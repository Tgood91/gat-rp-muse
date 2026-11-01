-- ============================================================
-- jobs.lua — Lesson 3: jobs
-- Built after inventory.lua (Lesson 1) and cars.lua (Lesson 2).
-- Plain Lua, no game-engine functions, no dependencies.
--
-- NEW IDEAS IN THIS LESSON
--   1. Earning: gold moves the OTHER way (gold = gold + pay).
--      Same recipe as always: check -> move -> report.
--   2. Choosing by name: currentJob holds a word ("mechanic"),
--      and an if / elseif / else chain sets each job's pay.
--   3. Systems connect: the taxi job needs the car key from
--      the inventory — no key, no job.
--
-- This file stands alone so you can run it by itself. It
-- reuses two things from inventory.lua with the same starting
-- values: gold = 600, carKey = 1.
-- ============================================================

-- From inventory.lua
gold = 600
carKey = 1          -- the key cut for YOUR car

-- The job: one slot per fact, same as the car
currentJob = "none" -- "none", "mechanic", or "taxi"
jobPay = 0          -- gold per shift; set by getJob()
shiftsWorked = 0

-- ============================================================
-- GET A JOB — the elseif chain picks the pay (or refuses)
-- ============================================================
function getJob(jobName)
    if jobName == "mechanic" then
        currentJob = "mechanic"
        jobPay = 80
        print("You're hired: mechanic, " .. jobPay .. " gold per shift.")
    elseif jobName == "taxi" then
        if carKey < 1 then
            print("Taxi drivers need their own car. No key, no job.")
        else
            currentJob = "taxi"
            jobPay = 120
            print("You're hired: taxi driver, " .. jobPay .. " gold per shift.")
        end
    else
        print("No such job: " .. jobName)
    end
end

-- ============================================================
-- WORK A SHIFT — the shop recipe, run backwards
-- check (have a job?) -> move (gold goes UP) -> report
-- ============================================================
function workShift()
    if currentJob == "none" then
        print("You don't have a job. Get hired first.")
    else
        gold = gold + jobPay
        shiftsWorked = shiftsWorked + 1
        print("Shift done: +" .. jobPay .. " gold. Gold: " .. gold ..
              " | Shifts worked: " .. shiftsWorked)
    end
end

-- ============================================================
-- QUIT — back to no job, no pay
-- ============================================================
function quitJob()
    currentJob = "none"
    jobPay = 0
    print("You quit. Currently unemployed.")
end

-- ============================================================
-- DISPLAY — print the job state
-- ============================================================
function showJob()
    print("Job: " .. currentJob .. " | Pay per shift: " .. jobPay ..
          " | Shifts worked: " .. shiftsWorked .. " | Gold: " .. gold)
end

-- ============================================================
-- TRY IT — get hired, work, quit, switch jobs
-- ============================================================
showJob()          -- none, gold 600
getJob("taxi")     -- needs the car key (have it) -> hired, 120/shift
workShift()        -- gold 720
workShift()        -- gold 840
quitJob()          -- unemployed
workShift()        -- refused: no job
getJob("mechanic") -- hired, 80/shift — no car needed
workShift()        -- gold 920
showJob()          -- the end state, all in one place
