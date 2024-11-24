use "collections"
use "time"
use "random"

// class Conversation
//   let _otherUser: String
//   let _content: Array[String] = Array[String]

//   new create(otherUser: String) =>
//     _otherUser = otherUser

//   fun addMessage(content: String) =>
//     _content.push(content + " (from " + _otherUser + ")")

actor Client
  let _env: Env
  let _simulator: ClientSimulator
  let _username: String
  let _engine: RedditEngine tag
  let _dirMsgs: Array[String] = Array[String]
  let _dirMsgsUsers: Array[String] = Array[String]
  let _subscriptions: Set[String] = Set[String]
  var _subreddit_name: String val

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

    // _env.out.print("Username: " + _username)
    // _env.out.print("Direct messages: ")
    // for key in _dirMsgs.values() do
    //   _env.out.print(key)
    // end
    // _env.out.print("Direct messages users: ")
    // for user in _dirMsgsUsers.values() do
    //   _env.out.print(user)
    // end


  new create(env: Env, simulator: ClientSimulator, username: String, engine: RedditEngine tag) =>
    _env = env
    _simulator = simulator
    _username = username
    _engine = engine
    _subreddit_name = subreddit_name

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
      // create_subreddit(_subreddit_name)
    else
      _env.out.print("Username doesn't exist!")
      register()
    end

  be registration_result(success: Bool, username: String) =>
    if success then
      _env.out.print("Welcome, " + username + "!")
      // _simulator.subreddit_created(_subreddit_name)
      create_subreddit(_subreddit_name)
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

  // send DM
  be send_direct_message(otherUser: String, content: String) =>
    // Check if conversation exists and get
    var conversation: Conversation = Conversation(_env, _username, otherUser) // Dummy conversation
    let key: String = conversation.keyBuilder(_username, otherUser)

    if _dirMsgs.contains(key) then
      // Send message to engine
      _engine.update_conversation(content, _username, otherUser, key, this)
    else
      _env.out.print("<send_direct_message>No conversation exists with " + key)
    end

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

  fun has(lis: Array[String], target: String): Bool =>
    for s in lis.values() do
      if s == target then
        return true
      end
    end
    false

  be create_subreddit(subreddit_name: String val) =>
    _engine.create_subreddit(this, subreddit_name, _username)

  be subreddit_creation_result(success: Bool, subreddit_name: String, subscriber_count: USize) =>
    if success then
      _simulator.subreddit_created()  // Notifying the simulator
    else
      _env.out.print("Sub-reddit \"" + subreddit_name + "\" already exists!")
    end

  be join_subreddit_result(success: Bool, subreddit_name: String, subscriber_count: USize) =>
    None

  be check_and_join_subreddit(subreddit_name: String) =>
    if not _subscriptions.contains(subreddit_name) then
      _engine.join_subreddit(this, _username, subreddit_name)
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

  

  // just writing them down, these behaviors and their logic in the backend still needs to be implemented

  // be create_subreddit(subreddit_name: String) =>
  //   _engine.create_subreddit(_username, subreddit_name)

  // be join_subreddit(subreddit_name: String) =>
  //   _engine.join_subreddit(_username, subreddit_name)
    
  // be leave_subreddit(subreddit_name: String) =>
  //   _engine.leave_subreddit(_username, subreddit_name)

  // be post_in_subreddit(subreddit_name: String, content: String) =>
  //   _engine.post_in_subreddit(_username, subreddit_name, content)

  // be comment_on_post(post_id: U64, content: String) =>
  //   _engine.comment_on_post(_username, post_id, content)

  // be comment_on_comment(comment_id: U64, content: String) =>
  //   _engine.comment_on_comment(_username, comment_id, content)

  // be upvote_post(post_id: U64) =>
  //   _engine.upvote_post(_username, post_id)

  // be downvote_post(post_id: U64) =>
  //   _engine.downvote_post(_username, post_id)

  // be upvote_comment(comment_id: U64) =>
  //   _engine.upvote_comment(_username, comment_id)

  // be downvote_comment(comment_id: U64) =>
  //   _engine.downvote_comment(_username, comment_id)

  // be get_feed() =>
  //   _engine.get_feed(_username)

  // be get_direct_messages() =>
  //   _engine.get_direct_messages(_username)

  // be send_direct_message(recipient: String, content: String) =>
  //   _engine.send_direct_message(_username, recipient, content)

  // more methods might need to be added based on simulation logic

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

  new create(env: Env, num_clients: USize, engine: RedditEngine tag, numDirMsgs: USize) =>
    _env = env
    _engine = engine
    _numDirMsgs = numDirMsgs
    _num_Clients = num_clients
    // _engine.set_simulator(this)

    // Step 1: Register all clients
    for i in Range(0, num_clients) do

      let username: String = "user" + i.string()
      let client: Client = Client(_env, this, username, _engine)
      let subreddit_name: String val = recover val "subreddit_" + (i+1).string() end
      client.start()
      _clients.push(client)
    end

    // run_direct_message_simulation()

  // Step 1 Check: Register all clients
  be update_registration_jobCount() =>
    _jobsDone = _jobsDone + 1
    _env.out.print("Registration jobsDone: " + _jobsDone.string())
    if _jobsDone == _clients.size().f64() then
      _jobsDone = 0
      _env.out.print("All clients registered")
      _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      create_direct_messages()
    end

  be subreddit_created() =>
    _created_subreddits = _created_subreddits + 1
    if _created_subreddits == _total_clients then
      //_env.out.print("All subreddits created. Starting join process.")
      _all_subreddits_created = true
      start_joining_subreddits()
    end

    be start_joining_subreddits() =>
      if _all_subreddits_created then
        for (i, client) in _clients.pairs() do
          for j in Range(0, _total_clients) do
            if i != j then
              let subreddit_to_join: String val = recover val "subreddit_" + (j + 1).string() end
              client.check_and_join_subreddit(subreddit_to_join)
            end
          end
        end
      end

  // Step 2: Create direct messages
  be create_direct_messages() =>
    // simulation logic needs to be added
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

  // Step 2 Check: Create direct messages
  be update_direct_messages_jobCount(increment: F64) =>
    _jobsDone = _jobsDone + increment
    let total = _num_Clients * _numDirMsgs
    // _env.out.print("TOTALJOBS: " + totalJobs.string())
    _env.out.print("Direct message created jobsDone: " + _jobsDone.string())
    _env.out.print("Total direct messages: " + total.string() + " clients: " + _num_Clients.string() + " numDirMsgs: " + _numDirMsgs.string())
    if _jobsDone == total.f64() then
      _jobsDone = 0
      _env.out.print("All direct messages created")
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

  // Step 3: Send dummy messages
  be send_dummy_messages() =>
    _env.out.print("SENDING DUMMY MESSAGES")
    for client in _clients.values() do
      // client.print_all_data()
      client.helper_send_dummy_message()
    end

  be increment_totalJobs(increment: USize) =>
    totalJobs = totalJobs + increment

  // Step 3 Check: Send dummy messages
  be update_dummy_messages_jobCount() =>
    _jobsDone = _jobsDone + 1
    let total = _num_Clients * _numDirMsgs * 2
    _env.out.print("Dummy messages jobsDone: " + _jobsDone.string() + " numDirMsgs(GOAL): " + totalJobs.string())
    if _jobsDone == totalJobs.f64() then
      _jobsDone = 0
      _env.out.print("jobsDone Counter set to 0: " + _jobsDone.string())
      // _env.out.print("All dummy messages sent")
      // _env.out.print("jobsDone Counter set to: " + _jobsDone.string())
      _engine.print_all_data()
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

  // be subreddit_created(subreddit_name: String) =>
  //   _subreddits.set(subreddit_name)

  // be get_existing_subreddits(client: Client tag) =>
  //   let subreddits_val: Array[String] val = recover val
  //     let temp = Array[String]
  //     for subreddit in _subreddits.values() do
  //       temp.push(subreddit)
  //     end
  //     temp
  //   end
  //   client.receive_existing_subreddits(subreddits_val)

actor Main
  new create(env: Env) =>
    let engine = RedditEngine(env)
    let simulator = ClientSimulator(env, 20, engine, 3)
    simulator.start_joining_subreddits()
    // engine.print_usernames()
