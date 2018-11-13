
# Debugging Smashing/Dashing

The stream of incoming dashboard data events can be watched through the following URL with the help of `curl` command:

    curl http://sales.devternity.com/events

To see incoming events in browser's Javascript console, just add the following line to any active widget's `ready` method:

    Dashing.debugMode = true

