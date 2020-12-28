class DemandsController < ApplicationController
    def show
        @demand = Demand.find(params[:id])
    end

    def new
        @demand = Demand.new
    end

    def create
        @demand = Demand.new(set_params)
        if @demand.save
            redirect_to edit_path(@demand)
        else
            render :new
        end
    end

    def edit
        @demand = Demand.find(params[:id])
    end

    def update
        @demand = Demand.find(params[:id])
        @demand.save!
        redirect_to demand_path(@demand)
    end

    private

  def set_params
    params.require(:demand).permit(:designator, :status)
  end
end
