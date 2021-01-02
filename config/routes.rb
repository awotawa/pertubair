Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'demands#home'
  resources :demands, only: [:new, :create, :edit, :update, :show]
  resources :demands, path: "users/:another_param/", only: [:show, :edit, :update, :destroy]
  get 'demands/:demand_id/additional_info', to: 'demands#additional_info'
end
