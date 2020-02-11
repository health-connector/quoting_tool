  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :samples

      resources :employees do
        collection do
          post :upload
          get :get_plans
          get :start_on_dates
        end
      end

      resources :products do
        collection do
          get :plans
          get :sbc_document
        end
      end
    end
  end
end
