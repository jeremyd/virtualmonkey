require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CukeMonk do
  it "checks a job status" do
    EM.run {
      cm = CukeMonk.new
      cm.run_test("NODEPLOY", "simple.feature")
      cm.run_test("NODEPLOY", "simple.feature")
      cm.run_test("NODEPLOY", "simple.feature")

      EM.add_periodic_timer(1) {
        cm.show_jobs
      }

      donetime = EM.add_periodic_timer(1) {
        donetime.cancel
        puts "All done? #{cm.all_done?}"
        if cm.all_done?
          EM.stop
        end
      }
        

    }
  end
end
