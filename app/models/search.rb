class Search < ApplicationRecord
  
  validates :logradouro,:numero,:bairro, presence: true 
  
end
