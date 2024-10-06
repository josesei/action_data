require "spec_helper"
require "action_data/base"

RSpec.describe ActionData::Base do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name
        t.timestamps
      end

      create_table :insurance_policies, force: true do |t|
        t.integer :user_id
        t.string :policy_number
        t.timestamps
      end

      create_table :payment_plans, force: true do |t|
        t.integer :insurance_policy_id
        t.string :plan_name
        t.timestamps
      end

      create_table :bills, force: true do |t|
        t.integer :payment_plan_id
        t.integer :amount
        t.timestamps
      end
    end

    class User < ActiveRecord::Base
      has_many :insurance_policies
    end

    class InsurancePolicy < ActiveRecord::Base
      belongs_to :user
      has_many :payment_plans
    end

    class PaymentPlan < ActiveRecord::Base
      belongs_to :insurance_policy
      has_many :bills
    end

    class Bill < ActiveRecord::Base
      belongs_to :payment_plan
    end

    User.create(id: 1, name: 'Alice')
    InsurancePolicy.create(id: 1, user_id: 1, policy_number: 'P123')
    PaymentPlan.create(id: 1, insurance_policy_id: 1, plan_name: 'Monthly Plan')
    Bill.create(id: 1, payment_plan_id: 1, amount: 100)
  end

  class UserActionData < ActionData::Base
    displayable_fields :name
    aggregatable_fields amount: [:sum]
    joinable_with 'InsurancePolicyActionData', by: :id
  end

  class InsurancePolicyActionData < ActionData::Base
    displayable_fields :policy_number
    joinable_with 'PaymentPlanActionData', by: :id
  end

  class PaymentPlanActionData < ActionData::Base
    displayable_fields :plan_name
    aggregatable_fields amount: [:sum]
    joinable_with 'BillActionData', by: :id
  end

  class BillActionData < ActionData::Base
    displayable_fields :amount
    aggregatable_fields amount: [:sum]
  end

  it 'aggregates total amount paid by user' do
    tree_structure = {
      UserActionData => {
        fields: [:name],
        children: {
          InsurancePolicyActionData => {
            children: {
              PaymentPlanActionData => {
                children: {
                  BillActionData => {
                    aggregates: { amount: :sum }
                  }
                }
              }
            }
          }
        }
      }
    }

    result = ActionData::Base.generate_query(tree_structure)

    expect(result.first['bills-sum-amount']).to eq(100)
  end
end
