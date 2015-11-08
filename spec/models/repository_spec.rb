require 'rails_helper'

RSpec.describe Repository, type: :model do
  it { should belong_to(:user) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:clone_url) }

  describe 'convert_files_to_class_list' do
    it 'returns multiple entries' do
      file_list = [
        'spec/lib/rumble/condition_spec.rb',
        'spec/lib/rumble/loop_spec.rb',
        'spec/lib/rumble/math_spec.rb',
      ]
      class_list = Repository.convert_files_to_class_list(file_list)

      expected = ['Rumble::Condition', 'Rumble::Loop', 'Rumble::Math']
      expect(class_list).to eq(expected)
    end
  end

end
