use "collections"
use "time"
use "random"

actor Client
  let _env: Env
  let _simulator: ClientSimulator
  let _username: String
  let _engine: RedditEngine tag

  let _dirMsgs: Array[String] = Array[String]
  let _dirMsgsUsers: Array[String] = Array[String]

  let _subscriptions: Set[String] = Set[String] // subreddits subscribed to
  var _subreddit_name: String val // user's subreddit - each user only has 1 subreddit and joining other >1 number of subreddits

  var _karma: I64 = 0 // karma points for all authored posts and comments

  new create(env: Env, simulator: ClientSimulator, username: String, engine: RedditEngine tag, subreddit_name: String) =>
    _env = env
    _simulator = simulator
    _username = username
    _engine = engine
    _subreddit_name = subreddit_name

  be print_all_data() =>
    var result: String = "Username: " + _username + "\n"
    result = result + "Direct messages: ["
    for key in _dirMsgs.values() do
      result = result + key + ", "
    end
    result = result + "]\n"

    result = result + "Direct messages users: ["
    for user in _dirMsgsUsers.values() do
      result = result + user + ", "
    end
    result = result + "]"

    _env.out.print(result)

  fun keyBuilder(user1: String, user2: String): String =>
    if user1 < user2 then
      return user1 + user2
    else
      return user2 + user1
    end

  be start() =>
    register()

  be register() =>
    _engine.register_account(this, _username)

  be login_result(success: Bool, username: String) =>
    if success then
      _env.out.print("Welcome back, " + username + "!")
    else
      _env.out.print("Username doesn't exist!")
      register()
    end

  be registration_result(success: Bool, username: String) =>
    if success then
      _env.out.print("Welcome, " + username + "!")
      // _simulator.subreddit_created(_subreddit_name)
      // create_subreddit(_subreddit_name) *** moving to after DM's created and printed
    else
      _env.out.print("Username already in use! "+ username)
      register()
    end
    _simulator.update_registration_jobCount()

  // create a new conversation with the other user
  be start_conversation(otherUser: String) =>
    let conversation = Conversation(_env, _username, otherUser)
    let key: String = conversation.keyBuilder(_username, otherUser)

    // _env.out.print("Starting conversation with " + otherUser + " from " + _username + " Key builder: " + key)

    if _dirMsgs.contains(key) then
      _env.out.print("CLIENT Conversation already exists with " + otherUser)
      _simulator.update_direct_messages_jobCount(1.0)  // job done even if not fulfilled - will cause a distribution
    else
      // _env.out.print("Starting conversation with " + otherUser)
      // _env.out.print("Key: " + key)

      // removed for concurrency - will be handled by engine using accept_conversation()
      // _dirMsgsUsers.push(otherUser)
      // _dirMsgs.push(key)

      _engine.start_conversation(_username, otherUser, key, this)
    end

  // accept new conversation
  be accept_conversation(otherUser: String, key: String) =>
    // _env.out.print("Conversation accepted from " + otherUser + " to " + _username + " Key: " + key)
    if _dirMsgs.contains(key) then
      _env.out.print("Conversation already exists with " + otherUser)
    else
      _env.out.print("Starting conversation accepted with " + key)
      _dirMsgsUsers.push(otherUser)
      _dirMsgs.push(key)
      // _simulator.increment_totalJobs1()
    end
    _simulator.update_direct_messages_jobCount(0.5)

  be send_direct_message_Key(key: String, recieverUser: String, content: String) =>
    if has(_dirMsgs, key) then  // _dirMsgs.contains(key)
      // Send message to engine
      _engine.update_conversation(content, recieverUser, _username, key, this)
    else
      var result: String =""
      for keyN in _dirMsgs.values() do
        result = result + keyN + ", "
      end
      _env.out.print("<send_direct_message_key>No conversation exists with " + key + " from " + _username + " keys: " + result)
      _simulator.update_dummy_messages_jobCount()
    end
    

  be update_conversation(senderUser: String, key: String) =>
    if has(_dirMsgs, key) then // _dirMsgs.contains(key)
      _env.out.print("Conversation updated with " + senderUser + " Key: " + key)
    else
      var res: String = ""
      for keyN in _dirMsgs.values() do
        res = res + keyN + ", "
      end
      _env.out.print("<update_conversation>No conversation exists with " + key + " keys: " + res)
    end
    _simulator.update_dummy_messages_jobCount()

  be display_conversation(key: String) =>
    // check if conversation exists
    if _dirMsgs.contains(key) then
      // Display conversation
      _env.out.print("Displaying conversation with " + key)
      _engine.display_conversation(key)
    else
      _env.out.print("No conversation exists with " + key)
    end

  be print_all_dirMsgs() =>
    for key in _dirMsgs.values() do
      display_conversation(key)
    end

  be helper_send_dummy_message() =>
    // _env.out.print(_username + " Sending dummy messages to other users in _dirMsgsUsers")
    _simulator.increment_totalJobs(_dirMsgsUsers.size())
    for otherUser in _dirMsgsUsers.values() do
      // _env.out.print(_username + " Sending dummy message to otherUser:" + otherUser)
      let key: String = keyBuilder(_username, otherUser)
      send_direct_message_Key(key, otherUser, "Hello, from " + _username + "!")
    end

  be update_direct_messages_jobCount(increment: F64) =>
    _simulator.update_direct_messages_jobCount(increment)

  be update_dummy_messages_jobCount() =>
    _simulator.update_dummy_messages_jobCount()

  be print_num_direct_messages() =>
    _env.out.print("Direct messages for " + _username + ": " + _dirMsgs.size().string())

  // Subsitute for contains() method of Array[String]
  fun has(lis: Array[String], target: String): Bool =>
    for s in lis.values() do
      if s == target then
        return true
      end
    end
    false

  be create_subreddit() =>
    _engine.create_subreddit(this, _subreddit_name, _username)

  be subreddit_creation_result(success: Bool, subreddit_name: String, subscriber_count: USize) =>
    if success then
      _simulator.subreddit_created()  // Notifying the simulator
    else
      _env.out.print("Sub-reddit \"" + subreddit_name + "\" already exists!")
    end

  be join_subreddit_result(success: Bool, subreddit_name: String, subscriber_count: USize) =>
    _simulator.update_subreddit_joining_jobCount()

  be check_and_join_subreddit(subreddit_name: String) =>
    if not _subscriptions.contains(subreddit_name) then
      _engine.join_subreddit(this, _username, subreddit_name)
    else
      _simulator.update_subreddit_joining_jobCount()
    end

  be update_subscriptions(subreddit_name: String) =>
    _subscriptions.set(subreddit_name)

  be print_subscriptions() =>
    _env.out.print(_username + "'s subscriptions:")
    for subscription in _subscriptions.values() do
      _env.out.print("- " + subscription)
    end

  be join_subreddit(subreddit_name: String) =>
    _engine.join_subreddit(this, _username, subreddit_name)

  be post_every_subreddit() =>
    for subreddit_name in _subscriptions.values() do
      _simulator.increment_totalJobs(1)
      _engine.client_post(this, _username, subreddit_name, "Hello from " + _username + " in " + subreddit_name)
    end

  be post_result(success: Bool, subreddit_name: String) =>
    if success then
      _env.out.print(_username + " posted in " + subreddit_name)
    else
      _env.out.print("<client.post_result>Error posting in " + subreddit_name)
    end
    _simulator.update_posting_jobCount()

  be make_comments() =>
    for subreddit_name in _subscriptions.values() do
      _simulator.increment_totalJobs(1)
      _engine.client_comment(this, _username, subreddit_name, "Comment from " + _username + " in " + subreddit_name)
    end

  be comment_result(success: Bool, subreddit_name: String) =>
    if success then
      _env.out.print(_username + " commented in " + subreddit_name)
    else
      _env.out.print("<client.comment_result>Error commenting in " + subreddit_name)
    end
    _simulator.update_comment_jobCount()

  be upvote_downvote() =>
    for subreddit_name in _subscriptions.values() do
      _simulator.increment_totalJobs(1)
      _engine.client_upvote_downvote(this, _username, subreddit_name)
    end

  be upvote_downvote_result(success: Bool, subreddit_name: String) =>
    if success then
      // _env.out.print(_username + " upvoted/downvoted in " + subreddit_name)
      None
    else
      _env.out.print("<client.upvote_downvote_result>Error upvoting/downvoting in " + subreddit_name)
    end
    _simulator.update_upvote_downvote_jobCount()

  be update_karma(karma: I64) =>
    _karma = karma
    _simulator.update_karma_jobCount()

  // be print_feed() =>
  //   let subscriptions: Array[String val] val = Array[String]
  //   for sub in _subscriptions.values() do
  //     subscriptions.push(sub)
  //   end

  //   _engine.get_client_feed(this, subscriptions)

  be print_feed() =>

    _engine.get_client_feed(this, _username)

  be feed_result() =>
    _simulator.feed_jobDone()

  be leave_subreddit(subreddit_name: String) =>
    _engine.leave_subreddit(this, _username, subreddit_name)

  be leave_subreddit_result(success: Bool, subreddit_name: String, subscriber_count: USize) =>
    if success then
      _env.out.print(_username + " successfully left subreddit \"" + subreddit_name + "\". Total subscribers: " + subscriber_count.string())
    else
      _env.out.print(_username + " failed to leave subreddit \"" + subreddit_name + "\" since he's the administrator.")
    end

  be remove_subscription(subreddit_name: String) =>
    _subscriptions.unset(subreddit_name)
  

  // Next Steps Layout -

/*

  [DONE] 1. Leave subreddits - Client query engine to leave "_engine.leave_subreddit(subreddit_name: String)"
  [DONE] 2. Each user post in every subreddit subscribed to - for each subreddit subscribed to, user calls "_engine.post(subreddit_name: String, _username: String, content: String)" (generates post in subreddit)
  [DONE] 3. only posts not comments 3. Comment under a post - user makes a comment under a posts/comments for each subreddit - "_engine.comment(subreddit_name: String, content: String)" - engine will randomize post/comment to comment under
  [DONE] - Randomize increment/decrement vote (Only voting on posts I believe) 4. Upvote/Downvote posts and comments - user upvotes/downvotes N(simulate multiple at simulator) random posts/comments - "_engine.upvote(subreddit_name: String)" - engine will randomize post/comment to upvote/downvote
  [DONE] 5. Compute Karama - tally upvotes - downvotes on a post/comment and assign value to post/comment author - "_engine.compute_karma(subreddit_name: String)" - call this after entire simulation is done
     engine will iterate through al posts/comments and compute karama and update a map of user -> karma. Then iterate through all users and update their karma. - "client(karma: Usize)"
  [DONE] 6. Get feed - get all posts from all subreddits subscribed to - "client.get_feed()"(called from simulator - iterate through all clients and call this method) -
     client will call "_engine.get_feed(subreddit_name: String)" for each subreddit subscribed to and print feed to terminal.
  [DONE] - Adding timer at each step 7. Performace metrics - time taken to perform all actions
     done later...

*/

  /*
    Every task needs returning result from engine. To know when task is complete.
  */

actor CustomTimer
  let _env: Env
  let _name: String
  var _start: U64
  var _end: U64

  new create(env: Env, name: String) =>
    _env = env
    _name = name
    _start = 0
    _end = 0

  be start() =>
    _start = Time.micros()

  be stop() =>
    _end = Time.micros()

  be print_time() =>
    let elapsed: U64 = _end - _start
    let seconds: U64 = elapsed / 1_000_000
    let remaining_micros: U64 = elapsed % 1_000_000
    let milliseconds: U64 = remaining_micros / 1_000
    let nanoseconds: U64 = (remaining_micros % 1_000) * 1_000

    _env.out.print(_name + " time: " + 
      seconds.string() + " seconds, " +
      milliseconds.string() + " milliseconds, " +
      nanoseconds.string() + " nanoseconds")

actor MetricsCollector
  let _env: Env
  let _engine: RedditEngine tag
  let _total_clients: USize
  let _start_time: I64
  var _counts_received: USize = 0

  new create(env: Env, engine: RedditEngine tag, total_clients: USize, start_time: I64) =>
    _env = env
    _engine = engine
    _total_clients = total_clients
    _start_time = start_time

  be collect_metrics(timers: Map[String, CustomTimer tag] val) =>
    let end_time = Time.now()
    let total_time = end_time._1 - _start_time
    
    _env.out.print("\nPerformance Metrics:\n")
    _env.out.print("Total time: " + total_time.string() + " seconds")
    _env.out.print("Number of subreddits created: " + _total_clients.string())
    _env.out.print("Total users: " + _total_clients.string())

    let timer_order = [
      "Registration"
      "Direct Messages"
      "Subreddit Creation"
      "Joining Subreddits"
      "Posting"
      "Commenting"
      "Upvote/Downvote"
      "Karma Calculation"
      "Get Feed"
      "Leaving Subreddits"
    ]

    for name in timer_order.values() do
      try
        timers(name)?.print_time()
      else
        _env.out.print("Timer '" + name + "' not found")
      end
    end
    
    _env.out.print("")
    for i in Range(1, _total_clients + 1) do
      let subreddit_name = recover val "subreddit_" + i.string() end
      _engine.get_subscriber_count(subreddit_name, this)
    end

  be receive_subscriber_count(subreddit_name: String, count: USize) =>
    if _counts_received == 0 then
      _env.out.print("\nFinal subscriber counts:")
    end
    _env.out.print(subreddit_name + ": " + count.string())
    _counts_received = _counts_received + 1
    if _counts_received == _total_clients then
      _env.out.print("\nMetrics collection complete.")
    end

actor ClientSimulator
  let _env: Env
  let _clients: Array[Client] = Array[Client]
  let _engine: RedditEngine tag
  let _numDirMsgs: USize
  var _jobsDone: F64 = 0
  let _num_Clients: USize
  var totalJobs: USize = 0
  var _created_subreddits: USize = 0
  var _all_subreddits_created: Bool = false
  let _rand: Random
  let _timers: Map[String, CustomTimer tag] val

  let _registration_timer: CustomTimer
  let _direct_messages_timer: CustomTimer
  let _subreddit_creation_timer: CustomTimer
  let _joining_timer: CustomTimer
  let _posting_timer: CustomTimer
  let _commenting_timer: CustomTimer
  let _upvote_downvote_timer: CustomTimer
  let _karma_timer: CustomTimer
  let _get_feed_timer: CustomTimer
  let _leaving_timer: CustomTimer

  new create(env: Env, num_clients: USize, engine: RedditEngine tag, numDirMsgs: USize) =>
    _env = env
    _engine = engine
    _numDirMsgs = numDirMsgs
    _num_Clients = num_clients
    _rand = Rand(Time.now()._1.u64(), Time.now()._2.u64())
    let timers = recover trn Map[String, CustomTimer tag] end

    _registration_timer = CustomTimer(_env, "Registration")
    _direct_messages_timer = CustomTimer(_env, "Direct Messages")
    _subreddit_creation_timer = CustomTimer(_env, "Subreddit Creation")
    _joining_timer = CustomTimer(_env, "Joining Subreddits")
    _posting_timer = CustomTimer(_env, "Posting")
    _commenting_timer = CustomTimer(_env, "Commenting")
    _upvote_downvote_timer = CustomTimer(_env, "Upvote/Downvote")
    _karma_timer = CustomTimer(_env, "Karma Calculation")
    _get_feed_timer = CustomTimer(_env, "Get Feed")
    _leaving_timer = CustomTimer(_env, "Leaving Subreddits")

    timers("Registration") = _registration_timer
    timers("Direct Messages") = _direct_messages_timer
    timers("Subreddit Creation") = _subreddit_creation_timer
    timers("Joining Subreddits") = _joining_timer
    timers("Posting") = _posting_timer
    timers("Commenting") = _commenting_timer
    timers("Upvote/Downvote") = _upvote_downvote_timer
    timers("Karma Calculation") = _karma_timer
    timers("Get Feed") = _get_feed_timer
    timers("Leaving Subreddits") = _leaving_timer 
    _timers = consume timers

    // DM - Step 1: Register all clients
    _registration_timer.start()
    for i in Range(0, num_clients) do

      let username: String = "user" + i.string()
      let subreddit_name: String val = recover val "subreddit_" + (i+1).string() end
      let client: Client = Client(_env, this, username, _engine, subreddit_name)
      client.start()
      _clients.push(client)
    end

  // DM - Step 1 Check: Register all clients
  be update_registration_jobCount() =>
    _jobsDone = _jobsDone + 1
    _env.out.print("Registration jobsDone: " + _jobsDone.string())
    if _jobsDone == _clients.size().f64() then
      _jobsDone = 0
      _env.out.print("All clients registered")
      _registration_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      create_direct_messages()
    end

  // DM - Step 2: Create direct messages
  be create_direct_messages() =>
    // simulation logic needs to be added
    _direct_messages_timer.start()
    _env.out.print("CREATING DIRECT MESSAGES")
    try
      for i in Range(0, _clients.size()) do
        let client: Client = _clients(i)?

        // Randomly select a user to send a direct message to
        let randomClients: Array[String] = get_random_clients(i)
        // _env.out.print("()()()()()Amount of random clients: " + randomClients.size().string()) // works
        for otherUser in randomClients.values() do
          client.start_conversation(otherUser)
        end
      end

      // _engine.print_num_direct_messages()
    else
      _env.out.print("Error in running direct message simulation " + _clients.size().string())
    end

  // DM - Step 2 Check: Create direct messages
  be update_direct_messages_jobCount(increment: F64) =>
    _jobsDone = _jobsDone + increment
    let total = _num_Clients * _numDirMsgs
    // _env.out.print("TOTALJOBS: " + totalJobs.string())
    _env.out.print("Direct message created jobsDone: " + _jobsDone.string())
    _env.out.print("Total direct messages: " + total.string() + " clients: " + _num_Clients.string() + " numDirMsgs: " + _numDirMsgs.string())
    if _jobsDone == total.f64() then
      _jobsDone = 0
      _env.out.print("All direct messages created")
      _direct_messages_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      send_dummy_messages()
    end

  fun get_random_clients(clientID: USize): Array[String] => 
    var remaining_clients: Array[USize] = Array[USize]
    for i in Range(0, _clients.size()) do
      remaining_clients.push(i)
    end
    remaining_clients.remove(clientID, 1)

    var res = Array[String]

    let current_time = Time.now()
    let seed1: U64 = current_time._2.u64()  // nanoseconds
    let seed2: U64 = current_time._1.u64()  // seconds

    let rng = Rand(seed1, seed2)

    try
      for i in Range(0, _numDirMsgs) do
        let random_client_index: U64 = rng.next() % remaining_clients.size().u64()
        let client: USize = remaining_clients(random_client_index.usize())?
        remaining_clients.remove(client, 1)
        res.push("user" + client.string())
      end
    else
      _env.out.print("Error in getting random clients")
    end

    res

  // DM - Step 3: Send dummy messages
  be send_dummy_messages() =>
    _env.out.print("SENDING DUMMY MESSAGES")
    for client in _clients.values() do
      // client.print_all_data()
      client.helper_send_dummy_message()
    end

  be increment_totalJobs(increment: USize) =>
    totalJobs = totalJobs + increment

  // DM - Step 3 Check: Send dummy messages
  be update_dummy_messages_jobCount() =>
    _jobsDone = _jobsDone + 1
    let total = _num_Clients * _numDirMsgs * 2
    _env.out.print("Dummy messages jobsDone: " + _jobsDone.string() + " numDirMsgs(GOAL): " + totalJobs.string())
    if _jobsDone == totalJobs.f64() then
      totalJobs = 0
      _jobsDone = 0
      _env.out.print("jobsDone Counter set to 0: " + _jobsDone.string())
      // _env.out.print("All dummy messages sent")
      // _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      _engine.print_all_data()
      // Create all subreddits
      create_subreddits()
    end

  // Subreddit - Step 1: Create subreddits
  be create_subreddits() =>
    _subreddit_creation_timer.start()
    // _env.out.print("CREATING AND JOINING SUBREDDITS") - isnt printing after engine.print_all_data()
    for client in _clients.values() do
      client.create_subreddit()
    end

  // Subreddit - Step 1 Check: Create subreddits
  be subreddit_created() =>
    _created_subreddits = _created_subreddits + 1
    if _created_subreddits == _num_Clients then
      //_env.out.print("All subreddits created. Starting join process.")
      _all_subreddits_created = true
      _subreddit_creation_timer.stop()
      start_joining_subreddits()
    end

  // Subreddit - Step 2: Join subreddits
  be start_joining_subreddits() =>
    _joining_timer.start()
    if _all_subreddits_created then
      for (i, client) in _clients.pairs() do
        for j in Range(0, _num_Clients) do
          if i != j then
            increment_totalJobs1()
            let subreddit_to_join: String val = recover val "subreddit_" + (j + 1).string() end
            client.check_and_join_subreddit(subreddit_to_join)
          end
        end
      end
    end

  // Subreddit - Step 2 Check: Join subreddits
  be update_subreddit_joining_jobCount() =>
    _jobsDone = _jobsDone + 1
    if _jobsDone == totalJobs.f64() then
      _jobsDone = 0
      totalJobs = 0
      _env.out.print("All clients joined subreddits")
      _joining_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      _env.out.print("totalJobs Counter set to: " + totalJobs.string())
      post_every_subreddit()
    end

  // Subreddit - Step 3: Post in every subreddit
  be post_every_subreddit() =>
    _posting_timer.start()
    for client in _clients.values() do
      client.post_every_subreddit()
    end

  // Subreddit - Step 3 Check: Post in every subreddit
  be update_posting_jobCount() =>
    _jobsDone = _jobsDone + 1
    if _jobsDone == totalJobs.f64() then
      _env.out.print("JobsDone: " + _jobsDone.string())
      _jobsDone = 0
      totalJobs = 0
      _env.out.print("All clients posted in subreddits")
      _posting_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      _env.out.print("totalJobs Counter set to: " + totalJobs.string())
      make_comments()
    end

  // Subreddit - Step 4: Make comments
  be make_comments() =>
    _commenting_timer.start()
    _env.out.print("MAKING COMMENTS")
    for client in _clients.values() do
      client.make_comments()
    end

  // Subreddit - Step 4 Check: Make comments
  be update_comment_jobCount() =>
    _jobsDone = _jobsDone + 1
    if _jobsDone == totalJobs.f64() then
      _env.out.print("JobsDone: " + _jobsDone.string())
      _jobsDone = 0
      totalJobs = 0
      _env.out.print("All clients commented in subreddits")
      _commenting_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      _env.out.print("totalJobs Counter set to: " + totalJobs.string())
      upvote_downvote()
    end

  // Subreddit - Step 5: Upvote/Downvote posts and comments
  be upvote_downvote() =>
    _upvote_downvote_timer.start()
    _env.out.print("UPVOTING/DOWNVOTING")
    for client in _clients.values() do
      client.upvote_downvote()
    end

  // Subreddit - Step 5 Check: Upvote/Downvote posts and comments
  be update_upvote_downvote_jobCount() =>
    _jobsDone = _jobsDone + 1
    if _jobsDone == totalJobs.f64() then
      _env.out.print("JobsDone: " + _jobsDone.string())
      _jobsDone = 0
      totalJobs = 0
      _env.out.print("All clients upvoted/downvoted in subreddits")
      _upvote_downvote_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      _env.out.print("totalJobs Counter set to: " + totalJobs.string())

      compute_karama()
    end

  be compute_karama() =>
    _karma_timer.start()
    _env.out.print("COMPUTING KARMA")
    _engine.compute_karma()

  be update_karma_jobCount() =>
    _jobsDone = _jobsDone + 1
    if _jobsDone == _num_Clients.f64() then
      _env.out.print("JobsDone: " + _jobsDone.string())
      _jobsDone = 0
      _env.out.print("All clients karma computed")
      _karma_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      print_feeds()
    end

  be print_feeds() =>
    _get_feed_timer.start()
    _env.out.print("PRINTING FEEDS")
    for client in _clients.values() do
      client.print_feed()
    end

  be feed_jobDone() =>
    _jobsDone = _jobsDone + 1
    if _jobsDone == _num_Clients.f64() then
      _env.out.print("JobsDone: " + _jobsDone.string())
      _jobsDone = 0
      _env.out.print("All feeds printed")
      _get_feed_timer.stop()
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
    end

  be increment_totalJobs1() =>
    totalJobs = totalJobs + 1

  be print_num_dirMsg() =>
    var sum: USize = 0
    for client in _clients.values() do
      client.print_num_direct_messages()
    end

  be print_all_dirMsgs() =>
    for client in _clients.values() do
      client.print_all_dirMsgs()
    end

  be start_leaving_subreddits() =>
    _leaving_timer.start()
    if _all_subreddits_created then
      for client in _clients.values() do
        let subreddits_to_leave = (_num_Clients - 1) / 2  // Half of joined subreddits
        for _ in Range(0, subreddits_to_leave) do
          let random_number = _rand.int(_num_Clients.u64()).usize() + 1
          let subreddit_to_leave: String val = recover val "subreddit_" + random_number.string() end
          client.leave_subreddit(subreddit_to_leave)
        end
      end
      _leaving_timer.start()
    end

  be print_performance_metrics(collector: MetricsCollector tag) =>
    collector.collect_metrics(_timers)

actor Main
  new create(env: Env) =>
    let start_time = Time.now()._1
    let engine = RedditEngine(env)
    let simulator = ClientSimulator(env, 5, engine, 1)
    simulator.start_joining_subreddits()

    let timers = Timers
    let leave_timer = Timer(LeaveNotify(simulator), 1_000_000_000) // 1 second delay
    timers(consume leave_timer)

    let metrics_timer = Timer(MetricsNotify(env, engine, 5, start_time, simulator), 2_000_000_000) // 2 seconds delay
    timers(consume metrics_timer)

class LeaveNotify is TimerNotify
  let _simulator: ClientSimulator tag

  new iso create(simulator: ClientSimulator tag) =>
    _simulator = simulator

  fun ref apply(timer: Timer, count: U64): Bool =>
    _simulator.start_leaving_subreddits()
    false

class MetricsNotify is TimerNotify
  let _env: Env
  let _engine: RedditEngine tag
  let _total_clients: USize
  let _start_time: I64
  let _simulator: ClientSimulator tag

  new iso create(env: Env, engine: RedditEngine tag, total_clients: USize, start_time: I64, simulator: ClientSimulator tag) =>
    _env = env
    _engine = engine
    _total_clients = total_clients
    _start_time = start_time
    _simulator = simulator

  fun ref apply(timer: Timer, count: U64): Bool =>
    let collector = MetricsCollector(_env, _engine, _total_clients, _start_time)
    _simulator.print_performance_metrics(collector)
    false

  fun ref cancel(timer: Timer) =>
    None
