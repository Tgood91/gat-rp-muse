-- ============================================================
-- shifts.lua — Lesson 12: the car you're in pays you
-- Built after jobs (3) and imports (11). New file alongside
-- jobs.lua, which is NOT modified. Plain Lua, no deps.
--
-- THE IDEA: Lesson 11's catalog promised "taxi shifts pay
-- +20 in the cab." Promises are just numbers until a system
-- READS them. Here, workShift() reads your current car and
-- the bonus goes live.
--
-- NEW IDEAS IN THIS LESSON
--   1. Jobs become a table too (Lesson 10's pattern applied
--      to Lesson 3): pay, key requirement, the specialized
--      car, and its bonus — all data, one place to change.
--   2. A bonus is a PAIRING: each job names its car. The
--      bonus pays only when currentCarKey matches it —
--      the cab boosts taxi, not delivery.
--   3. Pay is computed at shift time: pay = base + bonus,
--      and a missing bonus slot reads as nil, so
--      `job.bonus or 0` defaults it to 0.
--   4. Systems reading each other: jobs reads the garage
--      (Lesson 11) and the key (Lesson 1) without copying
--      either — currentCarKey is the bridge.
--
-- Starting values: gold 700 (Lesson 11's end), carKey 1
-- (Lesson 1), garage = the Sedan, Taxi Cab, Delivery Van.
-- Job pays are Lesson 3's, as Tanner set them: 80/40/100.
-- ============================================================

gold = 700
carKey = 1

-- The jobs: name -> { pay, needsKey, car, bonus }
jobs = {
    mechanic = { pay = 80 },
    taxi     = { pay = 40,  needsKey = true, car = "taxiCab",     bonus = 20 },
    delivery = { pay = 100, needsKey = true, car = "deliveryVan", bonus = 30 },
}

-- The garage (Lesson 11): keys you own, and their names
garageKeys = { "sedan", "taxiCab", "deliveryVan" }
carNames = {
    sedan = "Sedan", taxiCab = "Taxi Cab",
    deliveryVan = "Delivery Van", armoredSUV = "Armored SUV",
    zipzap = "ZipZap",
}
currentCarKey = "sedan"

-- Your job state
currentJob = "none"
shiftsWorked = 0

-- ============================================================
-- SET CAR — Lesson 11's swap, key-based
-- ============================================================
function setCar(carKeyName)
    local owned = false
    for i = 1, #garageKeys do
        if garageKeys[i] == carKeyName then owned = true end
    end
    if carNames[carKeyName] == nil then
        print("No such car: " .. carKeyName)
    elseif not owned then
        print("You don't own the " .. carNames[carKeyName] .. ".")
    else
        currentCarKey = carKeyName
        print("You're in the " .. carNames[carKeyName] .. ".")
    end
end

-- ============================================================
-- GET A JOB — lookup instead of the elseif chain
-- ============================================================
function getJob(jobName)
    local job = jobs[jobName]
    if job == nil then
        print("No such job: " .. jobName)
    elseif job.needsKey and carKey < 1 then
        print("That job needs a car. No key, no job.")
    else
        currentJob = jobName
        print("You're hired: " .. jobName .. ", " .. job.pay ..
              " gold per shift.")
    end
end

-- ============================================================
-- WORK A SHIFT — base pay, plus the pairing bonus
-- ============================================================
function workShift()
    if currentJob == "none" then
        print("You don't have a job. Get hired first.")
    else
        local job = jobs[currentJob]
        local bonus = 0
        if job.car == currentCarKey then
            bonus = job.bonus or 0
        end
        local pay = job.pay + bonus
        gold = gold + pay
        shiftsWorked = shiftsWorked + 1
        if bonus > 0 then
            print("Shift done: +" .. pay .. " gold (" .. job.pay ..
                  " base + " .. bonus .. " " ..
                  carNames[currentCarKey] .. " bonus). Gold: " .. gold)
        else
            print("Shift done: +" .. pay .. " gold. Gold: " .. gold)
        end
    end
end

-- ============================================================
-- QUIT + DISPLAY
-- ============================================================
function quitJob()
    currentJob = "none"
    print("You quit. Currently unemployed.")
end

function showStatus()
    print("Job: " .. currentJob .. " | Car: " ..
          carNames[currentCarKey] .. " | Shifts worked: " ..
          shiftsWorked .. " | Gold: " .. gold)
end

-- ============================================================
-- TRY IT — same job, different car, different pay
-- ============================================================
showStatus()          -- no job, in the Sedan, gold 700
getJob("taxi")        -- hired at 40
workShift()           -- Sedan: no bonus -> +40, gold 740
setCar("taxiCab")     -- climb into the cab
workShift()           -- pairing! +60 (40 + 20), gold 800
getJob("delivery")    -- hired at 100
workShift()           -- cab doesn't help delivery: +100, gold 900
setCar("deliveryVan") -- the right tool for the job
workShift()           -- pairing! +130 (100 + 30), gold 1030
getJob("mechanic")    -- hired at 80, no car pairing exists
workShift()           -- +80, gold 1110
showStatus()          -- the end state, all in one place
