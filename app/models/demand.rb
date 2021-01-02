class Demand < ApplicationRecord
    validates :designator, presence: true, format: { with: /\A[a-zA-Z]{2,3}\d{2,4}\Z/i, message: "Veuillez indiquer le numéro présent sur votre ticket, il est du type 'AB1234'" }
    validates :status, presence: true
    # validates :reason, presence: true
    # validates :additional, presence: true
end
