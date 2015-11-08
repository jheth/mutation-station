require 'rails_helper'

RSpec.describe Build, type: :model do
  it { should validate_presence_of(:status) }
end
