require 'rails_helper'

RSpec.describe Repository, type: :model do
  it { should belong_to(:user) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:clone_url) }
end
