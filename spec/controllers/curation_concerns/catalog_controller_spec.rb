require 'rails_helper'

describe CatalogController do
  before do
    ActiveFedora::Base.delete_all
  end

  describe 'when logged in' do
    #let(:user)    { stub_model(User, user_key: 'njaffer',email: 'njaffer@umich.edu', password: '123') }
    #user = User.create(email: "njaffer@umich.edu")
    #user.generate_password
    user = User.find_by_user_key("njaffer@umich.edu")
    let(:work1) { stub_model(GenericWork, id: '123abc', depositor: 'njaffer') }
    let(:work2) { stub_model(GenericWork, id: '124abc', depositor: 'njaffer') }
    let!(:collection) { stub_model(Collection, id: '123abc', depositor: 'njaffer') }
    let!(:file) { work1.file_sets.first }
    before do
      #visit new_user_session_path
      #fill_in 'Email', with: user.email
      #fill_in 'Password', with: user.password
      #click_button 'Log in' 
      #allow_any_instance_of(described_class).to receive(:authenticate!).and_return(true)
      #user = User.find_by_user_key("njaffer@umich.edu")
    end
    context 'Searching all content' do
      it 'excludes linked resources' do
        get 'data/index'
        expect(response).to be_successful
        expect(assigns(:document_list).map(&:id)).to match_array [work1.id, work2.id, collection.id]
      end
    end

    context 'Searching all works' do
      it 'returns all the works' do
        get 'index', 'f' => { 'generic_type_sim' => 'Work' }
        expect(response).to be_successful
        expect(assigns(:document_list).count).to eq 2
        [work1.id, work2.id].each do |work_id|
          expect(assigns(:document_list).map(&:id)).to include(work_id)
        end
      end
    end

    context 'Searching all collections' do
      it 'returns all the works' do
        get 'index', 'f' => { 'generic_type_sim' => 'Collection' }
        expect(response).to be_successful
        expect(assigns(:document_list).map(&:id)).to eq [collection.id]
      end
    end

    context 'searching just my works' do
      it 'returns just my works' do
        get 'index', works: 'mine', 'f' => { 'generic_type_sim' => 'Work' }
        expect(response).to be_successful
        expect(assigns(:document_list).map(&:id)).to eq [work1.id]
      end
    end

    context 'searching for one kind of work' do
      it 'returns just the specified type' do
        get 'index', 'f' => { 'human_readable_type_sim' => 'Generic Work' }
        expect(response).to be_successful
        expect(assigns(:document_list).map(&:id)).to include(work1.id, work2.id)
      end
    end
  end
end
