MaxPage.setup do
  group "The App Usage" do
    metric "Main feature has been used the last 24h",
            verify: true do
      true
      # Your code goes here.
    end

    metric 'PostgreSQL records count',
            description: "Heroku's Hobby Dev plan limits to 10,000.",
            verify: { max: 10_000 } do
      # Your code goes here.
      5230
    end
  end

  group "Delayed Job" do
    metric 'Failures',
            description: "Let's keep DJ without failures.",
            verify: { max: 0 } do
      # Your code goes here.
      0
    end

    metric 'Default queue size',
            description: 'No verifications, just for information.' do
      # Your code goes here.
      5
    end
  end
end
