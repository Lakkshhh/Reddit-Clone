use "collections"

// class Comment
//   let _author: String // username
//   let _commentMessage: String
//   let _replies: Array[Comment] = Array[Comment]
//   let voteCount: I64 = 0

// class Post
//   let _author: String // username
//   let _postMessage: String
//   let _comments: Array[Comment] = Array[Comment]
//   let voteCount: I64 = 0

actor RedditEngine
  let _env: Env
  let _usernames: Array[String] = Array[String]
  let _accounts: Map[String, Client] = Map[String, Client]
  let _subreddits: Map[String, Array[String]] = Map[String, Array[String]]
  let _subreddit_subscribers: Map[String, USize] = Map[String, USize]

  new create(env: Env) =>
    _env = env

  be check_username(client: Client tag, username: String) =>
    if _usernames.contains(username) then
      client.login_result(true, username)
    else
      client.login_result(false, username)
    end

  be register_account(client: Client tag, username: String) =>
    if not _usernames.contains(username) then
      _usernames.push(username)
      _accounts(username) = client
      client.registration_result(true, username)
    else
      client.registration_result(false, username)
    end

  be create_subreddit(client: Client tag, subreddit_name: String val, creator: String) =>
    if not _subreddits.contains(subreddit_name) then
      try
        _subreddits(subreddit_name) = Array[String]
        _subreddits(subreddit_name)?.push(creator)
        _subreddit_subscribers(subreddit_name) = 1
        client.subreddit_creation_result(true, subreddit_name, 1)
      else
        client.subreddit_creation_result(false, subreddit_name, 0)
      end
    else
      client.subreddit_creation_result(false, subreddit_name, 0)
    end

  be print_usernames() =>
    for username in _usernames.values() do
      _env.out.print(username)
    end

  be print_subreddits() =>
    for subreddit in _subreddits.keys() do
      let subscriber_count = _subreddit_subscribers.get_or_else(subreddit, 0)
      _env.out.print(subreddit + " (Subscribers: " + subscriber_count.string() + ")")
    end

  // be join_subreddit(client: Client tag, subreddit_name: String, username: String) =>
  //   try
  //     if _subreddits.contains(subreddit_name) then
  //       if not _subreddits(subreddit_name)?.contains(username) then
  //         _subreddits(subreddit_name)?.push(username)
  //         _subreddit_subscribers(subreddit_name) = _subreddit_subscribers.get_or_else(subreddit_name, 0) + 1
  //         client.join_subreddit_result(true, subreddit_name, _subreddit_subscribers(subreddit_name)?)
  //       else
  //         client.join_subreddit_result(false, subreddit_name, _subreddit_subscribers(subreddit_name)?)
  //       end
  //     else
  //       client.join_subreddit_result(false, subreddit_name, 0)
  //     end
  //   else
  //     client.join_subreddit_result(false, subreddit_name, 0)
  //   end

  // be get_feed(client: Client tag) =>
  //   for post in _subreddits.values() do
  //     client.display_post(post)
  //   end

  // be start_conversation(username: String, otherUser: String, conversation: Conversation) =>
  //   let otherClient = _accounts(otherUser)
  //   otherClient.accept_conversation(conversation)