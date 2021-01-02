class DemandsController < ApplicationController
  require 'open-uri'
  require 'nokogiri'

  def home
  end

  def show
    @demand = Demand.find(params[:id])
    @demand.indemnite = calculate_indemnisation(@demand)
    @demand.save
  end

  def new
    @demand = Demand.new
  end

  def create
    @demand = Demand.new(set_params)
    if @demand.save
      redirect_to edit_demand_path(@demand)
    else
      render :new
    end
  end

  def edit
    @demand = Demand.find(params[:id])
  end

  def update
    @demand = Demand.find(params[:id])
    @demand.indemnite = calculate_indemnisation(@demand)
    @route = plane_route(@demand.designator)
    @demand.departure_country = @route[0]
    @demand.arrival_country = @route[1]
    @demand.departure_airport = @route[2]
    @demand.arrival_airport = @route[3]
    @demand.departure_airport_iata = @route[4]
    @demand.arrival_airport_iata = @route[5]
    @demand.distance = distance_calculator(@route[4], @route[5])
    if @demand.update(set_params)
      redirect_to demand_path(@demand)
    else
      render :edit
    end
  end

  def additional_info
    @demand = Demand.find(params[:id])
  end

  private

  def set_params
    params.require(:demand).permit(:designator, :status, :reason, :additional, :rerouting)
  end

  # Will return the plane route given a flight designator
  def plane_route(designator)
    url = "https://www.flightradar24.com/data/flights/#{designator}"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    html_doc.search('#tbl-datatable > tbody > tr:nth-child(1) > td:nth-child(4)').each do |element|
      @country_dep = element.attribute('title').value # airport country (format: ', Country')
      @departure = element.text.strip # airport name and IATA code
    end
    html_doc.search('#tbl-datatable > tbody > tr:nth-child(1) > td:nth-child(5)').each do |element|
      @country_arr = element.attribute('title').value
      @arrival = element.text.strip
    end
    @departure_country = @country_dep.match(/, \w{0,}/).to_s.split[1] #from the selected ", France", i will be selecting only the country with this regex
    @arrival_country = @country_arr.match(/, \w{0,}/).to_s.split[1]
    @departure_airport = @departure # airport city and iata code of airport (format: 'Paris (CDG)')
    @arrival_airport = @arrival
    @departure_airport_iata = @departure.match(/\(\w{1,}/).to_s.split('(')[1] #isolate the IATA code for the airport
    @arrival_airport_iata = @arrival.match(/\(\w{1,}/).to_s.split('(')[1]
    [@departure_country, @arrival_country, @departure_airport, @arrival_airport, @departure_airport_iata, @arrival_airport_iata]
  end

  def is_in_eu?(country)
    # List of countries of the EU
    eu_countries = ['Austria', 'Italy', 'Belgium', 'Latvia', 'Bulgaria', 'Lithuania', 'Croatia', 'Luxembourg', 'Cyprus', 'Malta', 'Czechia', 'Netherlands', 'Denmark', 'Poland', 'Estonia', 'Portugal', 'Finland', 'Romania', 'France', 'Slovakia', 'Germany', 'Slovenia', 'Greece', 'Spain', 'Hungary', 'Sweden', 'Ireland']
    eu_countries.include?(country)
  end

  # Calculates the orthodromic distance between two airports given their IATA codes
  def distance_calculator(dep, arr) # iata codes for arrival and departure airports
    url = "https://www.greatcirclemapper.net/en/great-circle-mapper.html?route=#{dep}-#{arr}"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    html_doc.search('#panel > div > div.mod_airport_distance_result > div > div.item.total.clearfix > table').each do |element|
      @dist = element.text.strip # (format: 'Distance \n\n Travel Time \n\n 5107 nm, 9459 km \n 0:00 h')
    end
    @dist_tot = @dist.match(/\d{0,} km/).to_s # select only the value of xxx km
    @dist_value = @dist_tot.match(/\d{1,}/).to_s.to_i
  end

  def money_for_distance(dep_country, arr_country, dist, reach)
    if reach.nil?
      reach = 100000
    end
    if is_in_eu?(dep_country) && is_in_eu?(arr_country)
      if dist <= 1500
        reach_param(reach, 250, 2)
      elsif dist > 1500
        reach_param(reach, 400, 3)
      end
    else
      if dist <= 1500
        reach_param(reach, 250, 2)
      elsif dist > 1500 && dist <= 3500
        reach_param(reach, 400, 3)
      elsif dist > 3500
        reach_param(reach, 600, 4)
      end
    end
  end

  def reach_param(reach, compensation, upper_limit)
    compensation /= 2 if reach <= upper_limit
    compensation
  end

  # Conditions to get compensated
  # @problems = ["problèmes technique", "grève de la compagnie (pilotes, hôtesses de l'air, stewards, ...)", "n'ai pas été informé/ne sais pas"]
  # @retard = ["de plus de 3 heures"]
  # @notice = ["entre 1 à 2 semaines", "moins de 7 jours"]
  # @stopped = ["avant d'arriver à l'aéroport", "au comptoir d'enregistrement", "devant la porte d'embarquement"]
  # @because = ["d'un manque de place dans l'avion", "de problème(s) avec le personnel naviguant"]

  def calculate_indemnisation(demand)
    if is_in_eu?(plane_route(demand.designator)[0]) || is_in_eu?(plane_route(demand.designator)[1]) # verify that one of the airport is located in a EU country to apply the regulation 261-2004
      case demand.status
      when 'Annulation'
        annulation(demand)
      when 'Retard'
        retard(demand)
      when "Refus d'embarquement"
        refus_embarquement(demand)
      end
    else
      0
    end
  end

  def annulation(demand)
    if demand.additional == 'plus de 2 semaines'
      0
    elsif demand.additional == 'entre 1 à 2 semaines' && ['problèmes technique', "grève de la compagnie (pilotes, hôtesses de l'air, stewards, ...)", "n'ai pas été informé/ne sais pas"].include?(demand.reason)
      money_for_distance(demand.departure_country, demand.arrival_country, demand.distance, demand.rerouting)
    elsif demand.additional == 'moins de 7 jours' && ['problèmes technique', "grève de la compagnie (pilotes, hôtesses de l'air, stewards, ...)", "n'ai pas été informé/ne sais pas"].include?(demand.reason)
      money_for_distance(demand.departure_country, demand.arrival_country, demand.distance, demand.rerouting)
    end
  end

  def retard(demand)
    if demand.additional == 'moins de 3 heures'
      0
    elsif demand.additional == 'de plus de 3 heures' && ['problèmes technique', "grève de la compagnie (pilotes, hôtesses de l'air, stewards, ...)", "n'ai pas été informé/ne sais pas"].include?(demand.reason)
      money_for_distance(demand.departure_country, demand.arrival_country, demand.distance, demand.rerouting)
    end
  end

  def refus_embarquement(demand)
    if demand.additional == 'lors du contrôle de sécurité'
      0
    elsif ["avant d'arriver à l'aéroport", "au comptoir d'enregistrement", "devant la porte d'embarquement"].include?(demand.additional) && ["d'un manque de place dans l'avion", "de problème(s) avec le personnel naviguant"].include?(demand.reason)
      money_for_distance(demand.departure_country, demand.arrival_country, demand.distance, demand.rerouting)
    end
  end
end
