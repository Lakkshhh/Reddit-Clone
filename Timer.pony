use "time"

actor MyTimer
  let _env: Env
  var _start: U64
  var _end: U64

  new create(env: Env) =>
    _env = env
    _start = 0
    _end = 0

    // _env.out.print("Timer created")

  // Does not display x86 issue
  // be printCyclceCount()=>
  //   _env.out.print("Cycle count: " + Time.cycles().string())

  be start() =>
    _start = Time.micros()
    // _env.out.print("Timer started: " + _start.string())

  be stop() =>
    _end = Time.micros()
    // _env.out.print("Timer stopped: " + _end.string())

  be printTime() =>
    let elapsed: U64 = _end - _start
    // _env.out.print("end - start: " + _end.string() + " - " + _start.string())
    // _env.out.print("Time taken: " + elpased.string() + " nano seconds")

    // Convert elapsed time to seconds, milliseconds, and nanoseconds
    let seconds: U64 = elapsed / 1_000_000
    let remaining_micros: U64 = elapsed % 1_000_000
    let milliseconds: U64 = remaining_micros / 1_000
    let nanoseconds: U64 = (remaining_micros % 1_000) * 1_000

    _env.out.print("Time taken: " + 
    seconds.string() + " seconds, " +
    milliseconds.string() + " milliseconds, " +
    nanoseconds.string() + " nanoseconds")
