require 'rails_helper'
#require 'uri'

RSpec.configure do |config|
  config.filter_run_excluding :globus_enabled => :true unless Umrdr::Application.config.globus_enabled
end
describe "GlobusJob :globus_enabled => :true", :globus_enabled => :true do
describe GlobusRestartAllJob do
  let( :globus_dir ) { Pathname "/tmp/deepbluedata-globus" }
  let( :target_name ) { "DeepBlueData_Restart_All" }
  #let( :target_name_prep_dir ) { "#{Rails.env}_#{target_name}" }
  let( :globus_prep_dir ) { globus_dir.join 'prep' }
  let( :job_complete_file ) { globus_prep_dir.join ".test.restarted.#{target_name}" }
  let( :error_file ) { globus_prep_dir.join ".test.error.#{target_name}" }
  let( :lock_file ) { globus_prep_dir.join ".test.lock.#{target_name}" }

  describe "#perform" do
    context "when can acquire lock" do
      let( :job ) { j = GlobusCopyJob.new; j.define_singleton_method( :set_id, id ) { |id| @globus_concern_id = id; self }; j }
      let( :log_prefix ) { "Globus: globus_restart_all_job " }
      let( :globus_era_file ) { GlobusJob.token }
      let( :target ) { "DeepBlueData_" }
      let( :id00 ) { "id000" }
      let( :file00 ) { "#{globus_prep_dir}/.development.lock.#{target}#{id00}" }
      let( :dir00 ) { "#{globus_prep_dir}/development_#{target}#{id00}" }
      let( :dir00tmp ) { "#{dir00}_tmp" }
      let( :id01 ) { "id001" }
      let( :file01 ) { "#{globus_prep_dir}/.test.lock.#{target}#{id01}" }
      let( :dir01 ) { "#{globus_prep_dir}/test_#{target}#{id01}" }
      let( :dir01tmp ) { "#{dir01}_tmp" }
      let( :id02 ) { "id002" }
      let( :file02 ) { "#{globus_prep_dir}/.test.error.#{target}#{id02}" }
      let( :files ) { [globus_era_file,file00,dir00,dir00tmp,file01,dir01,dir01tmp,file02,file03,dir04,dir05tmp].map { |f| f.to_s }  }
      let( :id03 ) { "id003" }
      let( :file03 ) { "#{globus_prep_dir}/.test.lock.#{target}#{id03}" }
      let( :id04 ) { "id004" }
      let( :dir04 ) { "#{globus_prep_dir}/test_#{target}#{id04}" }
      let( :id05 ) { "id005" }
      let( :dir05tmp ) { "#{globus_prep_dir}/test_#{target}#{id05}_tmp" }
      before do
        File.delete lock_file if File.exists? lock_file
        File.delete error_file if File.exists? error_file
        File.delete job_complete_file if File.exists? job_complete_file
        allow( Rails.logger ).to receive( :debug ).with( any_args )
        expect( Dir ).to receive( :glob ).with( any_args ).and_return( files )
        allow( GlobusCopyJob ).to receive( :perform_later ).with( any_args )
      end
      it "calls globus block." do
        described_class.perform_now
        #expect( Rails.logger ).to have_received( :debug ).with( 'bogus so we can look at the logger output' )
        expect( GlobusCopyJob ).to have_received( :perform_later ).with( id01 )
        expect( GlobusCopyJob ).to have_received( :perform_later ).with( id02 )
        expect( GlobusCopyJob ).to have_received( :perform_later ).with( id03 )
        expect( GlobusCopyJob ).to have_received( :perform_later ).with( id04 )
        expect( GlobusCopyJob ).to have_received( :perform_later ).with( id05 )
        expect( GlobusCopyJob ).to have_received( :perform_later ).exactly( 5 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{log_prefix}restart all complete" )
        #expect( Rails.logger ).to have_received( :debug ).with( 'bogus so we can look at the logger output' )
        #expect( Rails.logger ).not_to have_received( :error )
        expect( File.exist? job_complete_file ).to eq( true )
        expect( File.exist? error_file ).to eq( false )
        expect( File.exist? lock_file ).to eq( false )
      end
      after do
        File.delete job_complete_file if File.exists? job_complete_file
      end
    end
  end

  describe "#globus_job_complete_file" do
    let( :job ) { described_class.new }
    before do
      job.define_singleton_method( :set_parms ) do @globus_concern_id = "Restart_All"; end
      job.set_parms
    end
    it "returns the ready file name." do
      expect( job.send( :globus_job_complete_file ) ).to eq( job_complete_file )
    end
  end

  describe "#globus_job_complete?" do
    let( :job ) { described_class.new }
    let( :job_complete_msg ) { " globus job complete file #{job_complete_file}" }
    let( :time_now ) { Time.now }
    let( :time_before_now ) { time_now - 9.seconds }

    before do
      job.define_singleton_method( :set_parms ) do @globus_concern_id = "Restart_All"; end
      job.set_parms
    end
    context "when file does not exist" do
      before do
        allow( Rails.logger ).to receive( :debug )
        expect( File ).to receive( :exists? ).with( job_complete_file ).and_return( false )
      end
      it "return true." do
        expect( job.send( :globus_job_complete? ) ).to eq( false )
        expect( Rails.logger ).to have_received( :debug ).with( job_complete_msg )
      end
    end
    context "when file exists and time matches" do
      before do
        allow( Rails.logger ).to receive( :debug )
        expect( File ).to receive( :exists? ).with( job_complete_file ).and_return( true )
        #expect( File ).to receive( :birthtime ).with( job_complete_file ).and_return( time_now )
        expect( job ).to receive( :last_complete_time ).with( job_complete_file ).and_return( time_now )
        expect( GlobusJob ).to receive( :token_time ).with( no_args ).and_return( time_now )
      end
      it "return true." do
        expect( job.send( :globus_job_complete? ) ).to eq( true )
        expect( Rails.logger ).to have_received( :debug ).with( job_complete_msg )
        #expect( Rails.logger ).to have_received( :debug ).with( 'bogus' )
      end
    end
    context "when file exists and time does not match" do
      before do
        allow( Rails.logger ).to receive( :debug )
        expect( File ).to receive( :exists? ).with( job_complete_file ).and_return( true )
        #expect( File ).to receive( :birthtime ).with( job_complete_file ).and_return( time_before_now )
        expect( job ).to receive( :last_complete_time ).with( job_complete_file ).and_return( time_before_now )
        expect( GlobusJob ).to receive( :token_time ).with( no_args ).and_return( time_now )
      end
      it "return false." do
        expect( job.send( :globus_job_complete? ) ).to eq( false )
        expect( Rails.logger ).to have_received( :debug ).with( job_complete_msg )
        #expect( Rails.logger ).to have_received( :debug ).with( 'bogus' )
      end
    end
  end
end
end