require 'ruby-debug'

module VirtualMonkey
  class MysqlToolboxRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    include VirtualMonkey::Mysql
    attr_accessor :scripts_to_run
    attr_accessor :s_main
    attr_accessor :s_restore
    attr_accessor :s_grow

    def setup_server_vars
      @s_main=@servers[0]
      @s_restore=@servers[1]
      @s_grow=@servers[2]
      raise "Need 3 servers" unless @s_main and @s_restore and @s_grow
    end

    # lookup all the RightScripts that we will want to run
    def lookup_scripts
      st = ServerTemplate.find(@s_main.server_template_href)
      @scripts_to_run = {}
      @scripts_to_run['promote'] = st.executables.detect { |ex| ex.name =~ /promote to master/ }
      @scripts_to_run['backup'] = st.executables.detect { |ex| ex.name =~ /EBS backup/ }
      @scripts_to_run['terminate'] = st.executables.detect { |ex| ex.name =~ /TERMINATE/ }
      # hardwired script! (this is an 'anyscript' that users typically use to setup the master dns)
      # This a special version of the register that uses MASTER_DB_DNSID instead of a test DNSID
      # This is identical to "DB register master"
      @scripts_to_run['master_init'] = RightScript.new('href' => "/api/acct/2901/right_scripts/195053")
      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /MySQL EBS Toolbox v2/ }
      # Use the HEAD revision.
      st = tbx[0]
      @scripts_to_run['restore'] = st.executables.detect { |ex| ex.name =~ /EBS restore/ }
      @scripts_to_run['create_backup_scripts'] = st.executables.detect { |ex| ex.name =~  /EBS create backup scripts/i }
      @scripts_to_run['enable_network'] = st.executables.detect { |ex| ex.name =~  /DB MySQL Enable Networking/i }
      @scripts_to_run['create_migrate_script'] = st.executables.detect { |ex| ex.name =~ /DB EBS create migrate script from MySQL EBS v1 master/ }
      @scripts_to_run['create_mysql_ebs_stripe'] = st.executables.detect { |ex| ex.name =~ /DB Create MySQL EBS/ }
      @scripts_to_run['grow_volume'] = st.executables.detect { |ex| ex.name =~  /DB EBS slave init and grow volume/i }
    end

    def create_master
      config_master_from_scratch(@s_main)
    end

    def create_backup
      run_script("backup",@s_main)
      wait_for_snapshots
    end

    def test_restore_grow
      grow_to_size=100
      restore_and_grow(@s_grow,grow_to_size,false)
      test_volume_data(@s_grow)
      test_volume_size(@s_grow,grow_to_size)
    end

    def test_restore
      restore_from_backup(@s_restore,false)
      test_volume_data(@s_restore)
    end
  end
end
