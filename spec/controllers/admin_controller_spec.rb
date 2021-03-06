require 'rails_helper'

describe AdminController do
  describe 'GET #index' do
    let(:user) { create(:user) }

    it 'succeeds for authorized user' do
      user.grant(:edit, :games)
      sign_in user

      get :index

      expect(response).to have_http_status(:success)
    end

    it 'redirects to root for unauthorized user' do
      sign_in user

      get :index

      expect(response).to redirect_to(root_path)
    end

    it 'redirects to root for unauthenticated' do
      get :index

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #statistics' do
    let(:user) { create(:user) }
    let(:visit) { create(:visit, user: user) }

    it 'succeeds for authorized' do
      user.grant(:edit, :games)
      sign_in user

      get :statistics

      expect(response).to have_http_status(:success)
    end
  end
end
