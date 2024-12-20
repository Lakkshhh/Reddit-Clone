use "collections"
use "random"
use "time"

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

class ref Comment
  let _author: String // username
  let _commentMessage: String
  let _replies: Array[Comment] ref = Array[Comment]
  let voteCount: I64 = 0

  new ref create(author: String, commentMessage: String) =>
    _author = author
    _commentMessage = commentMessage

  fun getFullComment_String(): String =>
    var result: String = "\nComment Author: " + _author + "\n Message: " + _commentMessage + "\nVotes: " + voteCount.string()
    for reply in _replies.values() do
      result = reply.getFullComment_String()
    end
    result

  fun getAuthor(): String =>
    _author

  fun getVoteCount(): I64 =>
    voteCount

class Post
  let _author: String // username
  let _postMessage: String
  let _comments: Array[Comment] = Array[Comment]
  var _voteCount: I64 = 0

  new create(author: String, postMessage: String) =>
    _author = author
    _postMessage = postMessage

  fun getFullPost_String(): String =>
    var result: String = "\nSubreddit Author: " + _author + "\n Message: " + _postMessage + "\nVotes: " + _voteCount.string()
    for comment in _comments.values() do
      result = comment.getFullComment_String()
    end
    result

  fun ref pushComment(comment: Comment) =>
    _comments.push(comment)

  fun ref incrementVote() =>
    _voteCount = _voteCount + 1

  fun ref decrementVote() =>
    _voteCount = _voteCount - 1

  fun ref getComments(): Array[Comment] =>
    _comments

  fun getAuthor(): String =>
    _author

  fun getVoteCount(): I64 =>
    _voteCount

actor RedditEngine
  let _env: Env
  // var _simulator: ClientSimulator tag
  let _usernames: Array[String] = Array[String]
  let _accounts: Map[String, Client] = Map[String, Client]

  let _direct_messages: Map[String, Conversation ref] = Map[String, Conversation] // authorUser+otherUser, Direct Messages

  // let _subreddit_subcribers: Map[String, Array[Post]] = Map[String, Array[Post]] // Username, Posts
  let _subscribers: Map[String, Array[String]] = Map[String, Array[String]] // Subreddit, Subscribers

  let _subreddits: Map[String, Array[Post]] = Map[String, Array[Post]]  // Key: Subreddit name, Value: [Post]

  let _subreddit_subcribers: Map[String, Array[String]] = Map[String, Array[String]] // Key: Subreddit name, Value: [userNames of subscribers]
  let _subreddit_subcriber_count: Map[String, USize] = Map[String, USize] // rename: "subreddit_subcriber_count" // Key: Subreddit name, Value: Number of subscribers

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

  // Subsitute for contains() method of Array[String]
  fun has(lis: Array[String], target: String): Bool =>
    for s in lis.values() do
      if s == target then
        return true
      end
    end
    false

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

  be get_subscriber_count(subreddit_name: String, collector: MetricsCollector tag) =>
    let count = _subreddit_subcriber_count.get_or_else(subreddit_name, 0)
    collector.receive_subscriber_count(subreddit_name, count)

  be create_subreddit(client: Client tag, subreddit_name: String val, creator: String) =>
    if not _subreddit_subcribers.contains(subreddit_name) then
      try
        _subreddit_subcribers(subreddit_name) = Array[String]
        _subreddit_subcribers(subreddit_name)?.push(creator)
        _subreddit_subcriber_count(subreddit_name) = 1
        _subreddits(subreddit_name) = Array[Post]
        _subscribers(subreddit_name) = Array[String]
        _subscribers(subreddit_name)?.push(creator)
        
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
    for subreddit in _subreddit_subcribers.keys() do
      let subscriber_count = _subreddit_subcriber_count.get_or_else(subreddit, 0)
      _env.out.print(subreddit + " (Subscribers: " + subscriber_count.string() + ")")
    end

  be join_subreddit(client: Client tag, username: String, subreddit_name: String) =>
    if _subreddit_subcribers.contains(subreddit_name) then
      try
        let subscribers = _subreddit_subcribers(subreddit_name)?
        if not subscribers.contains(username) then
          subscribers.push(username)
          _subreddit_subcribers(subreddit_name) = subscribers
          
          let subscriber_count = _subreddit_subcriber_count.get_or_else(subreddit_name, 0) + 1
          _subreddit_subcriber_count(subreddit_name) = subscriber_count
          
          if _accounts.contains(username) then
            let user_client = _accounts(username)?
            user_client.update_subscriptions(subreddit_name)
          end

          _subscribers(subreddit_name)?.push(username)
          
          _env.out.print(username + " joined '" + subreddit_name + "'. Total subscribers: " + subscriber_count.string())
          client.join_subreddit_result(true, subreddit_name, subscriber_count)
        else
          client.join_subreddit_result(false, subreddit_name, _subreddit_subcriber_count.get_or_else(subreddit_name, 0))
        end
      else
        client.join_subreddit_result(false, subreddit_name, 0)
      end
    else
      client.join_subreddit_result(false, subreddit_name, 0)
    end

  be client_post(client: Client tag, author: String, subreddit_name: String, postMessage: String) =>
    if _subreddit_subcribers.contains(subreddit_name) then
      try
        let posts = _subreddits(subreddit_name)?
        let post = Post(author, postMessage)
        posts.push(post)
        _subreddits(subreddit_name) = posts
        _env.out.print("Post added to '" + subreddit_name + "' by " + author)
        client.post_result(true, subreddit_name)
      else
        _env.out.print("<RedditEngine.client_post>Post failed to add to '" + subreddit_name + "' by " + author)
        var result: String = "Subscribers: "
        for sub in _subreddits.keys() do
          result = result + sub + " "
        end
        _env.out.print(result + " Goal:" + subreddit_name)
        client.post_result(false, subreddit_name)
      end
    else
      _env.out.print("<RedditEngine.client_post Final>Post failed to add to '" + subreddit_name + "' by " + author)
      client.post_result(false, subreddit_name)
    end

  be client_comment(client: Client tag, author: String, subreddit_name: String, commentMessage: String) =>
    if _subreddit_subcribers.contains(subreddit_name) then
      try
        let posts = _subreddits(subreddit_name)?

        let postIndex: U64 = get_randome_index(posts.size().u32())
        let post = posts(postIndex.usize())?

        // Randomize which comment to add to

        let comment = Comment(author, commentMessage)
        post.pushComment(comment)
        _env.out.print("Comment added to '" + subreddit_name + "' by " + author)
        client.comment_result(true, subreddit_name)
      else
        _env.out.print("<RedditEngine.client_comment>Comment failed to add to '" + subreddit_name + "' by " + author)
        client.comment_result(false, subreddit_name)
      end
    else
      _env.out.print("<RedditEngine.client_comment Final>Comment failed to add to '" + subreddit_name + "' by " + author)
      client.comment_result(false, subreddit_name)
    end

  fun get_randome_index(size: U32): U64 =>
    let current_time = Time.now()
    let seed1: U64 = current_time._2.u64()  // nanoseconds
    let seed2: U64 = current_time._1.u64()  // seconds

    let rng = Rand(seed1, seed2)

    let index: U64 = rng.next() % size.u64()
    index.u32()
    index

  be client_upvote_downvote(client: Client tag, username: String, subreddit_name: String) =>
    if _subreddit_subcribers.contains(subreddit_name) then
      try
        let posts = _subreddits(subreddit_name)?
        let postIndex: U64 = get_randome_index(posts.size().u32())
        let post = posts(postIndex.usize())?
        // TODO: Randomize upvote or downvote
        let upvote: Bool = randomTorF()
        if upvote then
          post.incrementVote() // upvote
          _env.out.print(username + " upvoted a post in '" + subreddit_name + "'")

        else
          _env.out.print(username + " downvote a post in '" + subreddit_name + "'")
          post.decrementVote() // downvote
        end

        post.incrementVote() // only upvoting + 1
        _env.out.print(username + " upvoted a post in '" + subreddit_name + "'")
        client.upvote_downvote_result(true, subreddit_name)
      else
        _env.out.print("<RedditEngine.client_upvote>Upvote failed in '" + subreddit_name + "'")
        client.upvote_downvote_result(false, subreddit_name)
      end
    else
      _env.out.print("<RedditEngine.client_upvote Final>Upvote failed in '" + subreddit_name + "'")
      client.upvote_downvote_result(false, subreddit_name)
    end

  fun randomTorF(): Bool =>
    // return random True or False
    let current_time = Time.now()
    let seed1: U64 = current_time._2.u64()  // nanoseconds
    let seed2: U64 = current_time._1.u64()  // seconds

    let rng = Rand(seed1, seed2)

    
    let value: U64 = rng.next()
    let zeroOne: U64 = value % 11

    _env.out.print("rng: " + value.string() + " zeroOne: " + zeroOne.string())

    if zeroOne > 5 then
      return false
    else
      return true
    end



  be compute_karma() =>
    let karmas: Map[String, I64] = Map[String, I64] // username, karma
    for username in _usernames.values() do
      karmas(username) = 0  // initialize karma to 0
    end

    try

      for subreddit in _subreddit_subcribers.keys() do
        let posts = _subreddits(subreddit)?
        // get post author karma and add post karma to author
        for post in posts.values() do
          let author: String = post.getAuthor()
          let karma: I64 = post.getVoteCount()
          karmas(author) = karmas(author)? + karma
          // get comment author karma and add comment karma to author
          for comment in post.getComments().values() do
            let commentAuthor: String = comment.getAuthor()
            let commentKarma: I64 = comment.getVoteCount()
            karmas(commentAuthor) = karmas(commentAuthor)? + commentKarma
          end
        end
      end

      for pair in karmas.pairs() do
        _env.out.print(pair._1 + " karma: " + pair._2.string())
        let client: Client = _accounts(pair._1)?
        client.update_karma(pair._2)
      end
    
    else
      _env.out.print("Error computing karma")
    end

  be get_client_feed(client: Client tag, username: String) =>
    var feed: String = "\n\n**" + username + "'s feed**: \n\n"
    try

      // _env.out.print("size of _subscribers: " + _subscribers.size().string())
      for pair in _subscribers.pairs() do
        // _env.out.print("Checking " + pair._1 + " for " + username + " in ")
        if has(pair._2, username) then
          let subreddit_name: String = pair._1
          let posts = _subreddits(subreddit_name)?
          feed = feed + "\n\n - Subreddit: " + subreddit_name + " - \n"
          for post in posts.values() do
            feed = feed + post.getFullPost_String()
          end
          // _env.out.print("GOINING")
        else
          _env.out.print("<get_client_feed>User not subscribed to any subreddit")
        end
      end
    else
      _env.out.print("Error getting client feed")
    end
    _env.out.print(feed)
    client.feed_result()
    _env.out.print("End of feed")


  be leave_subreddit(client: Client tag, username: String, subreddit_name: String) =>
    if _subreddit_subcribers.contains(subreddit_name) then
      try
        let subscribers = _subreddit_subcribers(subreddit_name)?
        let index = subscribers.find(username)?
        subscribers.delete(index)?
        _subreddit_subcribers(subreddit_name) = subscribers
        let subscriber_count = _subreddit_subcriber_count.get_or_else(subreddit_name, 1) - 1
        _subreddit_subcriber_count(subreddit_name) = subscriber_count
        if _accounts.contains(username) then
          let user_client = _accounts(username)?
          user_client.remove_subscription(subreddit_name)
        end
        client.leave_subreddit_result(true, subreddit_name, subscriber_count)
      else
        client.leave_subreddit_result(false, subreddit_name, _subreddit_subcriber_count.get_or_else(subreddit_name, 0))
      end
    else
      client.leave_subreddit_result(false, subreddit_name, 0)
    end
    client.leave_subreddit_complete()