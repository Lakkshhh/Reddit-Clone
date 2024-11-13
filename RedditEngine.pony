use "collections"

actor RedditEngine
  let _env: Env
  let _usernames: Array[String] = Array[String]
  let _accounts: Map[String, Account] = Map[String, Account]

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
      _accounts(username) = Account(username)
      client.registration_result(true, username)
    else
      client.registration_result(false, username)
    end

  // one by one gotta implement other methods

actor Main
  new create(env: Env) =>
    let engine = RedditEngine(env)
    let client = Client(env, engine)
    client.start()
