use "collections"

class Conversation
  let _otherUser: String
  let _content: Array[String] = Array[String]

  new create(otherUser: String) =>
    _otherUser = otherUser

  fun addMessage(content: String) =>
    _content.push(content + " (from " + _otherUser + ")")

actor Client
  let _env: Env
  let _username: String
  let _engine: RedditEngine tag
  let _dirMsgs: Map[String, Conversation] = Map[String, Conversation]

  new create(env: Env, username: String, engine: RedditEngine tag) =>
    _env = env
    _username = username
    _engine = engine

  be start() =>
    register()

  be register() =>
    _engine.register_account(this, _username)
    

  be login_result(success: Bool, username: String) =>
    if success then
      // _username = username
      // _connected = true
      _env.out.print("Welcome back, " + username + "!")
      // will call a method (get_feed()) here to display the main reddit feed
    else
      _env.out.print("Username doesn't exist!")
      register()
    end

  be registration_result(success: Bool, username: String) =>
    if success then
      // _username = username
      // _connected = true
      _env.out.print("Welcome, " + username + "!")
      // will call a method (get_feed()) here to display the main reddit feed
    else
      _env.out.print("Username already in use!")
      register()
    end

  // create a new conversation with the other user
  be start_conversation(otherUser: String) =>
    let conversation = Conversation(otherUser)
    _engine.start_conversation(_username, otherUser, conversation)

  // send DM
  be send_direct_message(otherUser: String, content: String) =>
    let conversation = _dirMsgs.find(conversation => conversation._otherUser == otherUser)
    if conversation == None then
      conversation = Conversation(otherUser)
      _dirMsgs.push(conversation)
    end
    conversation.addMessage(content)

  be accept_conversation(conversation: Conversation) =>
    _dirMsgs.push(conversation)

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

  new create(env: Env, num_clients: USize, engine: RedditEngine tag) =>
    _env = env
    _engine = engine
    
    for i in Range(0, num_clients) do

      let username: String = "user" + i.string()
      let client: Client = Client(_env, username, _engine)
      client.start()
      _clients.push(client)
    end

  // be run_simulation() =>
    // simulation logic needs to be added
    

actor Main
  new create(env: Env) =>
    let engine = RedditEngine(env)
    let simulator = ClientSimulator(env, 10, engine)
    engine.print_usernames()
    // simulator.run_simulation()
