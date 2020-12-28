Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :demands, only: [:new, :create, :edit, :update, :show]
  get 'additional_info', to: 'demands#additional_info'
end