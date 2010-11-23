module VirtualMonkey
  class MysqlToolboxRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    include VirtualMonkey::Mysql
    attr_accessor :scripts_to_run

    def lookup_scripts
      @scripts_mysql = [
                         [ 'promote', 'EBS promote to master' ],
                         [ 'backup', 'EBS backup' ],
                         [ 'terminate', 'TERMINATE SERVER' ]
                       ]
      @scripts_my_toolbox = [
                              [ 'create_backup_scripts', 'EBS create backup scripts' ],
                              [ 'enable_network', 'DB MySQL Enable Networking' ],
                              [ 'create_migrate_script', 'DB EBS create migrate script from MySQL EBS v1' ],
                              [ 'create_mysql_ebs_stripe', 'DB Create MySQL EBS stripe' ],
                              [ 'grow_volume', 'DB EBS slave init and grow stripe volume' ],
                              [ 'restore', 'DB EBS restore stripe volume v2' ]
                            ]
      st = ServerTemplate.find(s_one.server_template_href)
      @scripts_to_run = {}
      @scripts_mysql.each { |a|
        @scripts_to_run[ a[0] ] = st.executables.detect { |ex| ex.name =~ /#{a[1]}/ }
        raise "FATAL: Script #{a[1]} not found" unless @scripts_to_run[ a[0] ]
      }
      # hardwired script! (this is an 'anyscript' that users typically use to setup the master dns)
      # This a special version of the register that uses MASTER_DB_DNSID instead of a test DNSID
      # This is identical to "DB register master" However it is not part of the template.
      @scripts_to_run['master_init'] = RightScript.new('href' => "/api/acct/2901/right_scripts/195053")
#TODO - this is hardcoded for 5.0 toolbox - need to deal with issue that we have two
#toolboxes and their names are going to change
      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /MySQL 5.0 EBS Stripe Toolbox v5 images v1/ }
      raise "FATAL: could not find toolbox" unless tbx
      # Use the HEAD revision.
      st = tbx[0]
      @scripts_my_toolbox.each { |a|
        @scripts_to_run[ a[0] ] = st.executables.detect { |ex| ex.name =~ /#{a[1]}/ }
        raise "FATAL: Script #{a[1]} not found" unless @scripts_to_run[ a[0] ]
      }
    end

    def create_master
      config_master_from_scratch(s_one)
    end
  end
end
