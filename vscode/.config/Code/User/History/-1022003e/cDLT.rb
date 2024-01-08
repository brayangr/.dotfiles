require 'rails_helper'

RSpec.describe Remuneration::SalaryPaymentDraftsController, type: :controller do
  let(:community) { create(:community, :set_remuneration_setting) }

  describe 'GET /remuneraciones/libro_liquidaciones' do
    before do
      login(user, community: community)
    end

    context 'when the user is super admin' do
      let(:user) { create(:user_superadmin) }

      it 'should return status 200' do
        get :index

        expect(response.status).to be(200)
      end
    end

    context 'when the user is admin' do
      let(:community_user_admin) { create(:community_user_admin, community: community) }
      let(:user) { community_user_admin.user }

      it 'should return status 200' do
        login(user, community: community)
        get :index

        expect(response.status).to be(200)
      end
    end

    context 'when the user have permission to edit employees' do
      let(:community_user) do
        community_user = create(:community_user_attendant, community: community)
        create(:permission, community_user: community_user, code: 'employees', value: 2)

        community_user
      end

      let(:user) { community_user.user }

      it 'should return status 200' do
        get :index

        expect(response.status).to be(200)
      end
    end

    context 'when the user have permission to view employees' do
      let(:community_user) do
        community_user = create(:community_user_attendant, community: community)
        create(:permission, community_user: community_user, code: 'employees', value: 1)

        community_user
      end

      let(:user) { community_user.user }

      it 'should redirect' do
        get :index

        expect(response.status).to redirect_to(remuneration_employees_path)
      end
    end
  end

  describe 'GET /remuneraciones/libro_liquidaciones/dias_trabajados' do
    before do
      login(user, community: community)
    end

    context 'when the user is super admin' do
      let(:user) { create(:user_superadmin) }

      it 'should return status 200' do
        get :worked_days

        expect(response.status).to be(200)
      end
    end

    context 'when the user is admin' do
      let(:community_user_admin) { create(:community_user_admin, community: community) }
      let(:user) { community_user_admin.user }

      it 'should return status 200' do
        login(user, community: community)
        get :worked_days

        expect(response.status).to be(200)
      end
    end

    context 'when the user have permission to edit employees' do
      let(:community_user) do
        community_user = create(:community_user_attendant, community: community)
        create(:permission, community_user: community_user, code: 'employees', value: 2)

        community_user
      end

      let(:user) { community_user.user }

      it 'should return status 200' do
        get :worked_days

        expect(response.status).to be(200)
      end
    end

    context 'when the user have permission to view employees' do
      let(:community_user) do
        community_user = create(:community_user_attendant, community: community)
        create(:permission, community_user: community_user, code: 'employees', value: 1)

        community_user
      end

      let(:user) { community_user.user }

      it 'should redirect' do
        get :worked_days

        expect(response.status).to redirect_to(remuneration_employees_path)
      end
    end
  end

  describe 'POST /remuneraciones/libro_liquidaciones/reset' do
    before do
      login(user, community: community)
    end

    context 'when the user is super admin' do
      let(:user) { create(:user_superadmin) }

      it 'should return status 200' do
        post :reset, params: { id: 1 }

        expect(response.status).to be(302)
      end
    end

    context 'when the user is admin' do
      let(:community_user_admin) { create(:community_user_admin, community: community) }
      let(:user) { community_user_admin.user }

      it 'should return status 302' do
        login(user, community: community)
        post :reset, params: { id: 1 }

        expect(response.status).to be(302)
      end
    end

    context 'when the user have permission to edit employees' do
      let(:community_user) do
        community_user = create(:community_user_attendant, community: community)
        create(:permission, community_user: community_user, code: 'employees', value: 2)

        community_user
      end

      let(:user) { community_user.user }

      it 'should return status 302' do
        post :reset, params: { id: 1 }

        expect(response.status).to be(302)
      end
    end

    context 'when the user have permission to view employees' do
      let(:community_user) do
        community_user = create(:community_user_attendant, community: community)
        create(:permission, community_user: community_user, code: 'employees', value: 1)

        community_user
      end

      let(:user) { community_user.user }

      it 'should redirect' do
        post :reset, params: { id: 1 }

        expect(response.status).to redirect_to(remuneration_employees_path)
      end
    end




    describe 'GET /remuneraciones/libro_liquidaciones/save' do
      before do
        login(user, community: community)
      end

      context 'when the user is super admin' do
        let(:user) { create(:user_superadmin) }

        it 'should return status 302' do
          get :save

          expect(response.status).to be(302)
        end
      end

      context 'when the user is admin' do
        let(:community_user_admin) { create(:community_user_admin, community: community) }
        let(:user) { community_user_admin.user }

        it 'should return status 302' do
          login(user, community: community)
          post :save

          expect(response.status).to be(302)
        end
      end

      context 'when the user have permission to edit employees' do
        let(:community_user) do
          community_user = create(:community_user_attendant, community: community)
          create(:permission, community_user: community_user, code: 'employees', value: 2)

          community_user
        end

        let(:user) { community_user.user }

        it 'should return status 302' do
          get :save

          expect(response.status).to be(302)
        end
      end

      context 'when the user have permission to view employees' do
        let(:community_user) do
          community_user = create(:community_user_attendant, community: community)
          create(:permission, community_user: community_user, code: 'employees', value: 1)

          community_user
        end

        let(:user) { community_user.user }

        it 'should redirect' do
          get :save

          expect(response.status).to redirect_to(remuneration_employees_path)
        end
      end

      context 'when tab is worked_days' do
        let(:user) { create(:user_superadmin) }

        it 'redirects to worked_days path' do
          expect(response.status).to redirect_to(worked_days_remuneration_salary_payment_drafts_path)
        end

        context 'when filters are applied' do
          it 'redirects with the filters' do
            params = { month: 10, year: 2023, employee_finder: 'test' }
            get :save, params: params

            expect(response.status).to redirect_to(remuneration_employees_path)
          end
        end
      end
    end
  end
end
