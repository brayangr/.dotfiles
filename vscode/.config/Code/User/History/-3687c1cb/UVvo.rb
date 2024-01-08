require 'rails_helper'

RSpec.describe Types::Tables::AccessControl::CommunityPropertyUsersTableType, 'CommunityPropertyUsersTableQuery' do
  include_context(:access_control_user)
  include_context(:without_user)

  let(:query) do
    <<-GRAPHQL
      query CommunityPropertyUsersTable {
        communityPropertyUsers {
          nodes {
            fullUserName
            propertyId
            propertyUserId
            propertyName
          }
        }
      }
    GRAPHQL
  end

  let(:admin_context) do
    {
      current_user: current_gql_user,
      current_community: current_gql_community,
      current_ability: Abilities::AccessControl.new(current_gql_user)
    }
  end

  let(:response) { DefaultInitSchema.execute(query, variables: nil, context: admin_context)['data']['communityPropertyUsers']['nodes'] }

  describe 'Successful Cases' do
    context 'when filter without headers' do
      it 'return data from all the properties' do
        random_property = properties.sample

        expect(response.select { |property| property['propertyId'] == random_property.id.to_s }.first['propertyUserId']).to eq(random_property.property_users.first.id.to_s)
      end

      it 'return full names' do
        random_property = properties.sample
        random_property.users.first.update(first_name: 'aaaa')

        expect(response.select { |property_info| property_info['propertyId'] == random_property.id.to_s }.first['fullUserName'].titleize).to eq(random_property.users.first.full_name)
      end

      it 'should only get lessees and owners' do
        property = properties.first
        property_user = property.property_users.first
        property_user.update(role: Constants::PropertyUser::ROLES[:broker])

        properties = response.index_by { |item| item['propertyId'] }

        expect(properties.dig(property.id.to_s, 'propertyUserId')).to be(nil)
      end

      it 'should not collect property users without access control enabled' do
        property = properties.first
        property_user = property.property_users.first
        property_user.update(access_control_enabled: false)

        properties = response.index_by { |item| item['propertyId'] }

        expect(properties.dig(property.id.to_s, 'propertyUserId')).to be(nil)
      end
    end
  end

  describe 'Failed cases' do

    # returns community not found error when community does not exist
    it_behaves_like :single_error, I18n.t('messages.errors.community.not_found') do
      let(:result) do
        admin_context[:current_community] = nil
        DefaultInitSchema.execute(query, variables: nil, context: admin_context)
      end
    end

    # returns not authorized error when there is no current user
    it_behaves_like :single_error, I18n.t(:not_authorized_error) do
      let(:result) do
        current_gql_user.update(email: Faker::Internet.email)
        admin_context[:current_ability] = Abilities::AccessControl.new(current_gql_user)
        DefaultInitSchema.execute(query, variables: nil, context: admin_context)
      end
    end
  end
end
