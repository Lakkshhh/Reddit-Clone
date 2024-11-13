use "collections"

actor Client
  let _env = _env
  let _username: String
  let _engine: RedditEngine tag

  new create(env: Env, engine: RedditEngine tag) =>
    _env = env
    _username = ""
    _engine = engine

  be start() =>
    _env.out.print("New User? (y/n): ")
    try
      match _env.input()?.lower()
        | "y" => sign_up()
        | "n" => sign_in()
      else
        _env.out.print("Invalid choice. Please try again.")
        start()
      end
    else
      _env.out.print("Error reading input. Please try again.")
      start()
    end

  be sign_in() =>
    _env.out.print("Enter your username: ")
    try _engine.check_username(this, _env.input()?)
    else _env.out.print("Error reading input. Please try again."); sign_in() end

  be sign_up() =>
    _env.out.print("Choose a username: ")
    try _engine.register_account(this, _env.input()?)
    else _env.out.print("Error reading input. Please try again."); sign_up() end

  be login_result(success: Bool, username: String) =>
    if success then
      _username = username
      _connected = true
      _env.out.print("Welcome back, " + _username + "!")
      // will call a method (get_feed()) here to display the main reddit feed
    else
      _env.out.print("Username doesn't exist!")
      sign_in()
    end

  be registration_result(success: Bool, username: String) =>
    if success then
      _username = username
      _connected = true
      _env.out.print("Welcome, " + _username + "!")
      // will call a method (get_feed()) here to display the main reddit feed
    else
      _env.out.print("Username already in use!")
      sign_up()
    end

  // just writing them down, these behaviors and their logic in the backend still needs to be implemented

  be create_subreddit(subreddit_name: String) =>
    _engine.create_subreddit(_username, subreddit_name)

  be join_subreddit(subreddit_name: String) =>
    _engine.join_subreddit(_username, subreddit_name)
    
  be leave_subreddit(subreddit_name: String) =>
    _engine.leave_subreddit(_username, subreddit_name)

  be post_in_subreddit(subreddit_name: String, content: String) =>
    _engine.post_in_subreddit(_username, subreddit_name, content)

  be comment_on_post(post_id: U64, content: String) =>
    _engine.comment_on_post(_username, post_id, content)

  be comment_on_comment(comment_id: U64, content: String) =>
    _engine.comment_on_comment(_username, comment_id, content)

  be upvote_post(post_id: U64) =>
    _engine.upvote_post(_username, post_id)

  be downvote_post(post_id: U64) =>
    _engine.downvote_post(_username, post_id)

  be upvote_comment(comment_id: U64) =>
    _engine.upvote_comment(_username, comment_id)

  be downvote_comment(comment_id: U64) =>
    _engine.downvote_comment(_username, comment_id)

  be get_feed() =>
    _engine.get_feed(_username)

  be get_direct_messages() =>
    _engine.get_direct_messages(_username)

  be send_direct_message(recipient: String, content: String) =>
    _engine.send_direct_message(_username, recipient, content)

  // more methods might need to be added based on simulation logic

actor ClientSimulator
  let _env: Env
  let _clients: Array[Client] = Array[Client]
  let _engine: RedditEngine tag

  new create(env: Env, num_clients: USize, engine: RedditEngine tag) =>
    _env = env
    _engine = engine
    
    for i in Range(0, num_clients) do
      let username = "user" + i.string()
      let client = Client(_env, username, _engine)
      _clients.push(client)
    end

  be run_simulation() =>
    // simulation logic needs to be added

actor Main
  new create(env: Env) =>
    let engine = RedditEngine(env)
    let simulator = ClientSimulator(env, 1000, engine)
    simulator.run_simulation()
