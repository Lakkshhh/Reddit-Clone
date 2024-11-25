use "collections"

class ref Conversation
  let _authorUser: String
  let _otherUser: String
  let _content: Array[String] ref = Array[String]
  let _env: Env

  new ref create(env: Env, authorUser: String, otherUser: String) =>
    _env = env
    _authorUser = authorUser
    _otherUser = otherUser

  fun get_otherUser(): String =>
    _otherUser

  fun get_authorUser(): String =>
    _authorUser

  fun ref addMessage(content: String) =>
    _content.push(content + " (from " + _otherUser + ")")

  fun printConversation() =>
    _env.out.print("Conversation between " + _authorUser + " and " + _otherUser)
    let tab: String = "    "
    for message in _content.values() do
      _env.out.print(tab + message)
    end

  fun keyBuilder(user1: String, user2: String): String =>
    if user1 < user2 then
      return user1 + user2
    else
      return user2 + user1
    end

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
  // var _simulator: ClientSimulator tag
  let _usernames: Array[String] = Array[String]
  let _accounts: Map[String, Client] = Map[String, Client]

  let _direct_messages: Map[String, Conversation ref] = Map[String, Conversation] // authorUser+otherUser, Direct Messages

  // let _subreddits: Map[String, Array[Post]] = Map[String, Array[Post]] // Username, Posts
  let _subscribers: Map[String, Array[String]] = Map[String, Array[String]] // Subreddit, Subscribers
  let _subreddits: Map[String, Array[String]] = Map[String, Array[String]]
  let _subreddit_subscribers: Map[String, USize] = Map[String, USize]

  be print_all_data() =>
    var result: String = "Usernames: \n"
    for username in _usernames.values() do
      result = result + username + " "
    end
    result = result + "\nAccounts: \n"
    for account in _accounts.keys() do
      result = result + account + " "
    end
    result = result + "\ndirect_messages keys: \n"
    for key in _direct_messages.keys() do
      result = result + key + " "
    end
    _env.out.print(result)

    _env.out.print("ALL " + _direct_messages.size().string() + " CONVERSATIONS: ")
    for conversation in _direct_messages.values() do
      conversation.printConversation()
    end

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
        
        if _accounts.contains(creator) then
          let user_client = _accounts(creator)?
          user_client.update_subscriptions(subreddit_name)
        end
        
        _env.out.print("Subreddit '" + subreddit_name + "' created by " + creator + "! Total subscribers: 1")
        client.subreddit_creation_result(true, subreddit_name, 1)
      else
        client.subreddit_creation_result(false, subreddit_name, 0)
      end
    else
      client.subreddit_creation_result(false, subreddit_name, 0)
    end

  be start_conversation(user: String, otherUser: String, key: String, userClient: Client) =>
    
    try
      let otherClient: Client = _accounts(otherUser)?
      let sender: Client = _accounts(user)?
      if _direct_messages.contains(key) then
        _env.out.print("ENGINE Conversation already exists with " + key)
        userClient.update_direct_messages_jobCount(1.0)
      else
        // _env.out.print("Starting conversation on engine with " + key)
        let conversation = Conversation(_env, user, otherUser)
        _direct_messages.update(key, conversation)
        otherClient.accept_conversation(user, key)
        sender.accept_conversation(otherUser, key)
      end
    else
      _env.out.print("otherUser doesn't exist to start conversation on engine: " + key)
      userClient.update_direct_messages_jobCount(1.0) // might have problems
    end

  be update_conversation(content: String, recieverUser: String, senderUser: String, key: String, senderClient: Client) =>
    try
      let convo: Conversation = _direct_messages.apply(key)?
      convo.addMessage(content)
      // _env.out.print("ENGINE: Updated conversation with " + key)
      // convo.printConversation()
      if _accounts.contains(recieverUser) then
        let reciever = _accounts(recieverUser)?
        reciever.update_conversation(senderUser, key)
      else 
        _env.out.print("Reciever doesn't exist in engine to update conversation: " + key)
        senderClient.update_dummy_messages_jobCount()
      end
    else
      _env.out.print("Conversation doesn't exist to update: " + key)
      senderClient.update_dummy_messages_jobCount()
    end

  be display_conversation(key: String) =>
    try
      let conversation = _direct_messages(key)?
      conversation.printConversation()
    else
      _env.out.print("Conversation doesn't exist with " + key)
    end

  be print_direct_messages() =>
    for conversation in _direct_messages.values() do
      conversation.printConversation()
    end

  be print_subreddits() =>
    for subreddit in _subreddits.keys() do
      let subscriber_count = _subreddit_subscribers.get_or_else(subreddit, 0)
      _env.out.print(subreddit + " (Subscribers: " + subscriber_count.string() + ")")
    end

  be join_subreddit(client: Client tag, username: String, subreddit_name: String) =>
    if _subreddits.contains(subreddit_name) then
      try
        let subscribers = _subreddits(subreddit_name)?
        if not subscribers.contains(username) then
          subscribers.push(username)
          _subreddits(subreddit_name) = subscribers
          
          let subscriber_count = _subreddit_subscribers.get_or_else(subreddit_name, 0) + 1
          _subreddit_subscribers(subreddit_name) = subscriber_count
          
          if _accounts.contains(username) then
            let user_client = _accounts(username)?
            user_client.update_subscriptions(subreddit_name)
          end
          
          _env.out.print(username + " joined '" + subreddit_name + "'. Total subscribers: " + subscriber_count.string())
          client.join_subreddit_result(true, subreddit_name, subscriber_count)
        else
          client.join_subreddit_result(false, subreddit_name, _subreddit_subscribers.get_or_else(subreddit_name, 0))
        end
      else
        client.join_subreddit_result(false, subreddit_name, 0)
      end
    else
      client.join_subreddit_result(false, subreddit_name, 0)
    end


  // be get_feed(client: Client tag) =>
  //   for post in _subreddits.values() do
  //     client.display_post(post)
  //   end

