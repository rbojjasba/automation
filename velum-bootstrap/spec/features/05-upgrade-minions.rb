require "spec_helper"
require 'yaml'

feature "update Admin Node" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:hostnames) { environment["minions"].map { |m| m["fqdn"] if m["role"] != "admin" }.compact }

  before(:each) do
    login
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after(:each) do
    Capybara.reset_sessions!
  end

  scenario "User updates the cluster" do
    with_status_ok do
      visit "/"
    end

    puts ">>> Wait for update-all-nodes button to be enabled"
    with_screenshot(name: :update_all_nodes_button_enabled) do
      expect(page).to have_link(id: "update-all-nodes", wait: 120)
    end
    puts "<<< update-all-nodes button enabled"

    puts ">>> Wait until all minions are pending an update"
    with_screenshot(name: :pending_update) do
      expect(page).to have_text("Update Available", count: node_number, wait: 120)
    end
    puts "<<< All minions are pending an update"

    puts ">>> Click to update all nodes"
    with_screenshot(name: :update_all_nodes_button_click) do
      find('#update-all-nodes').click
    end
    puts ">>> update all nodes clicked"

    # Allow 10 seconds for Velum to re-render nodes with spinners
    sleep 10

    # Min of 3600 seconds, Max of 7200 seconds, ideal = nodes * 120 seconds
    update_timeout = [[3600, node_number * 120].max, 7200].min
    puts ">>> Wait until update is complete (Timeout: #{update_timeout})"
    with_screenshot(name: :update_complete) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o, .fa-times-circle", count: node_number, wait: update_timeout)
      end
    end
    puts "<<< Update completed"

    puts ">>> Update succeeded"
    with_screenshot(name: :update_succeeded) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o", count: node_number, wait: 5)
      end
    end
    puts "<<< Update succeeded"
  end
end
