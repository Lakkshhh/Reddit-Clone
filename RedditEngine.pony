use "collections"

class Comment
  let _author: String #username
  let _commentMessage: String
  let _replies: Array[Comment] = Array[Comment]
  let voteCount: I64 = 0

class Post
  let _author: String #username
  let _postMessage: String
  let _comments: Array[Comment] = Array[Comment]
  let voteCount: I64 = 0

actor RedditEngine
  let _env: Env
  let _usernames: Array[String] = Array[String]
  let _accounts: Map[String, Client] = Map[String, Client]
  let _subreddits: Map[String, Array[Post]] = Map[String, Array[Post]] # Username, Posts
  let _subscribers: Map[String, Array[String]] = Map[String, Array[String]] # Subreddit, Subscribers

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

  be print_usernames() =>
    for username in _usernames.values() do
      _env.out.print(username)
    end

  be get_feed(client: Client tag) =>
    for post in _subreddits.values() do
      client.display_post(post)
    end

  be start_conversation(username: String, otherUser: String, conversation: Conversation) =>
    let otherClient = _accounts(otherUser)
    otherClient.accept_conversation(conversation)

  // one by one gotta implement other methods

// actor Main
//   new create(env: Env) =>
//     let engine = RedditEngine(env)
//     let client = Client(env, engine)
//     client.start()
