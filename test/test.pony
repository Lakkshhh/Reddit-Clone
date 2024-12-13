use "collections"

// class StringBuilder
//   var _env: Env
//   new create(env: Env) =>
//     _env = env

//   fun keyBuilder(user1_g: String, user2_g: String): String =>
//     if user1_g < user2_g then
//       return user1_g + user2_g
//     else
//       return user2_g + user1_g
//     end

//   fun has(lis: Array[String], target: String): Bool =>
//     for s in lis.values() do
//       if s == target then
//         return true
//       end
//     end
//     false



actor Main
  new create(env: Env) =>

    let m: Map[String, U64] = Map[String, U64]
    m("user1") = 1
    m("user2") = 2
    m("user3") = 3
    m("user4") = 4


    for p in m.pairs() do
      env.out.print(p._1 + " : " + p._2.string())
    end

    
    // let b: StringBuilder = StringBuilder.create(env)

    // let lis: Array[String] = []

    // let user1: String = "user1"
    // let user2: String = "user2"
    // let user3: String = "user3"
    // let user4: String = "user4"

    // lis.push(b.keyBuilder(user1, user2))
    // lis.push(b.keyBuilder(user1, user3))
    // lis.push(b.keyBuilder(user1, user4))
    // lis.push(b.keyBuilder(user2, user3))

    // env.out.print("Keys in lis:")
    // for i in lis.values() do
    //   env.out.print(i + " (length: " + i.size().string() + ")")
    // end

    // let check_key: String = "user1user3"
    // env.out.print("Checking for key: " + check_key + " (length: " + check_key.size().string() + ")")

    // if lis.contains(check_key) then
    //   env.out.print("yes")
    // else
    //   env.out.print("no")
    // end

    // for i in lis.values() do
    //   if i == check_key then
    //     env.out.print("Manual check: Match found for " + i)
    //   else
    //     env.out.print("Manual check: No match for " + i)
    //   end
    // end

    // let boo = b.has(lis, "user1user3")
    // if boo then
    //     env.out.print("hurya")
    // else 
    //     env.out.print("uuuhh")
    // end
