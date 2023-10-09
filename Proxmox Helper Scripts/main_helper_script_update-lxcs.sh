---
- hosts: all
  become: true
  tasks:
  - name: Delete Script if Present
    register: reg_del_script
    ignore_errors: True
    retries: 3
    delay: 3
    ansible.builtin.file:
      path: /tmp/main_helper_script_update-lxcs.sh
      state: absent

  - name: Send Notify to Telegram - Delete Script Failed
    when: reg_del_script is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nError Deleting Script\n\n{{reg_del_script}}"
        disable_web_page_preview: True
        disable_notification: False

  - name: Fail Job - Delete Script Failed
    when: reg_del_script is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nError Deleting Script\n\n{{reg_del_script}}"
    
###################################

  - name: Download Script from Repository
    register: reg_download_script
    ignore_errors: True
    retries: 3
    delay: 3
    get_url: 
      url: https://raw.githubusercontent.com/chaharsanjeev/homeLabAnsibleScripts/main/Proxmox%20Helper%20Scripts/main_helper_script_update-lxcs.sh
      dest: /tmp/main_helper_script_update-lxcs.sh
      
  - name: Send Notify to Telegram - Download Script from Repository Failed
    when: reg_download_script is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nError Downloading Script\n\n{{reg_download_script}}"
        disable_web_page_preview: True
        disable_notification: False

  - name: Fail Job - Download Script from Repository Failed
    when: reg_download_script is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nError Downloading Script\n\n{{reg_download_script}}"

###################################

  - name: Change Script Permission For Execute
    register: reg_change_mode
    ignore_errors: True
    retries: 3
    delay: 3
    ansible.builtin.file:
      path: /tmp/main_helper_script_update-lxcs.sh
      mode: '7777'

  - name: Send Notify to Telegram - Change Script Permission Failed
    when: reg_change_mode is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nError Change Script Permission\n\n{{reg_change_mode}}"
        disable_web_page_preview: True
        disable_notification: False

  - name: Fail Job - Change Script Permission Failed
    when: reg_change_mode is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nError Change Script Permission\n\n{{reg_change_mode}}"

###################################

  - name: Execute Update App Script
    register: reg_update_app_script
    ignore_errors: True
    retries: 3
    delay: 3
    shell: /tmp/main_helper_script_update-lxcs.sh

  - name: Send Notify to Telegram - Execute Delete Log Script Failed
    when: reg_update_app_script is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nExecute Delete Log Script\n\n{{reg_update_app_script}}"
        disable_web_page_preview: True
        disable_notification: False

  - name: Fail Job - Execute Delete Log Script Failed
    when: reg_update_app_script is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nExecute Delete Log Script\n\n{{reg_update_app_script}}"

###################################

  - name: Delete Update App Script
    register: reg_delete_script
    ignore_errors: True
    retries: 3
    delay: 3
    file: 
      path: /tmp/main_helper_script_update-lxcs.sh 
      state: absent

  - name: Send Notify to Telegram - Delete Update App Script
    when: reg_delete_script is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nDelete Delete Update App Script\n\n{{reg_delete_script}}"
        disable_web_page_preview: True
        disable_notification: False
  
  - name: Fail Job - Delete Update App Script Failed
    when: reg_delete_script is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nDelete Delete Update App Script\n\n{{reg_delete_script}}"
  
###################################
  
  - name: Update all Installed Packages
    ignore_errors: True
    retries: 3
    delay: 3
    apt:
      name: '*'
      state: latest
      update_cache: yes
      only_upgrade: yes
    register: apt_update_status

  - name: Send Notify to Telegram - Update all Installed Packages Failed
    when: apt_update_status is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nError Updating Installed Packages\n\n{{apt_update_status}}"
        disable_web_page_preview: True
        disable_notification: False
   
  - name: Fail Job - Update all Installed Packages Failed
    when: apt_update_status is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nError Updating Installed Packages\n\n{{apt_update_status}}"
   
###################################

  - name: Remove Packages Not Needed
    register: reg_remove_packages
    ignore_errors: True
    retries: 3
    delay: 3
    apt:
      autoremove: yes
      autoclean: yes

  - name: Send Notify to Telegram - Remove Packages Not Needed
    when: reg_remove_packages is failed
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nRemove Packages Not Needed\n\n{{reg_remove_packages}}"
        disable_web_page_preview: True
        disable_notification: False

  - name: Fail Job - Remove Packages Not Needed
    when: reg_remove_packages is failed
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nRemove Packages Not Needed\n\n{{reg_remove_packages}}"

###################################

  - name: Check If Reboot Required
    ignore_errors: True
    retries: 3
    delay: 3
    stat:
      path: /var/run/reboot-required
    register: reboot_required_file

  - name: Send Notify to Telegram - Restart Machine
    when: reboot_required_file.stat.exists == true
    ignore_errors: False
    retries: 3
    delay: 3
    delegate_to: localhost
    register: telegram_error
    community.general.telegram:
      token: "{{telegraph_token}}"
      api_args:
        chat_id: "{{telegraph_chatid}}"
        parse_mode: "plain"
        text: "From Job Server(monitor.sc) \n\nImpacted Host: {{ansible_hostname}}\n\nHost require reboot since kernal was updated"
        disable_web_page_preview: True
        disable_notification: False

  - name: Fail Job - Send Telegram Messages
    when: (reboot_required_file.stat.exists == true) and (telegram_error is failed)
    retries: 3
    delay: 3
    ansible.builtin.fail:
      msg: "Impacted Host: {{ansible_hostname}}\n\nError Sending Telegram Message\n\n{{telegram_error}}"

###################################
