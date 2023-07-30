local MySQL = MySQL
local db = {}

local SELECT_USERID = ('SELECT `userid` FROM `users` WHERE `%s` = ? LIMIT ?, 1;'):format(Server.PRIMARY_IDENTIFIER)
---Select the userid for a player based on their identifier.
---@param identifier string
---@param offset? number
---@return number?
function db.getUserFromIdentifier(identifier, offset)
    return MySQL.scalar.await(SELECT_USERID, { identifier, offset or 0 })
end

local INSERT_USER = 'INSERT INTO `users` (`username`, `license2`, `steam`, `fivem`, `discord`) VALUES (?, ?, ?, ?, ?)'
---Register a new user when a player first joins the server, and return their userid.
---@param username string
---@param identifiers {[string]: string}
---@return number
function db.createUser(username, identifiers)
    return MySQL.prepare.await(INSERT_USER,
        { username, identifiers.license2, identifiers.steam, identifiers.fivem, identifiers.discord }) --[[@as number]]
end

local SELECT_CHARACTERS = 'SELECT `charid`, `stateid`, `firstname`, `lastname`, `x`, `y`, `z`, `heading`, DATE_FORMAT(`last_played`, "%d/%m/%Y") AS `last_played` FROM `characters` WHERE `userid` = ? AND `deleted` IS NULL'
---Select all characters owned by the player.
---@param userid number
---@return table
function db.selectCharacters(userid)
    return MySQL.query.await(SELECT_CHARACTERS, { userid }) or {}
end

local SELECT_CHARACTER_DATA = 'SELECT `is_dead` AS `isDead`, `gender`, DATE_FORMAT(`dateofbirth`, "%d/%m/%Y") AS `dateofbirth`, `phone_number` as `phoneNumber`, `health`, `armour`, `statuses` FROM `characters` WHERE `charid` = ?'
---Select metadata for a character.
---@param charid any
---@return { isDead: boolean, gender: string, dateofbirth: string, phoneNumber: string, health?: number, armour?: number, statuses?: string }
function db.selectCharacterData(charid)
    return MySQL.single.await(SELECT_CHARACTER_DATA, { charid }) or {}
end

local INSERT_CHARACTER = 'INSERT INTO `characters` (`userid`, `stateid`, `firstname`, `lastname`, `gender`, `dateofbirth`, `phone_number`) VALUES (?, ?, ?, ?, ?, ?, ?)'
local INSERT_CHARACTER_INVENTORY = 'INSERT INTO `character_inventory` (`charid`) VALUES (?)'
---Register a new character for the user and returns the charid.
---@param userid number
---@param stateid string
---@param firstName string
---@param lastName string
---@param gender string
---@param date number
---@param phone_number number?
---@return number?
function db.createCharacter(userid, stateid, firstName, lastName, gender, date, phone_number)
    local charid = MySQL.prepare.await(INSERT_CHARACTER, { userid, stateid, firstName, lastName, gender, date, phone_number }) --[[@as number]]
    MySQL.prepare.await(INSERT_CHARACTER_INVENTORY, { charid })

    return charid
end

local UPDATE_CHARACTER = 'UPDATE characters SET `x` = ?, `y` = ?, `z` = ?, `heading` = ?, `is_dead` = ?, `last_played` = ?, `health` = ?, `armour` = ?, `statuses` = ? WHERE `charid` = ?'
---Update character data for one or multiple characters.
---@param parameters table<number, any> | table<number, any>[]
function db.updateCharacter(parameters)
    MySQL.prepare.await(UPDATE_CHARACTER, parameters)
end

local DELETE_CHARACTER = 'UPDATE `characters` SET `deleted` = curdate() WHERE `charid` = ?'
---Sets a character as deleted, preventing the user from accessing it.
---@param charid number
function db.deleteCharacter(charid)
    return MySQL.update(DELETE_CHARACTER, { charid })
end

local SELECT_CHARACTER_GROUPS = 'SELECT `name`, `grade` FROM `character_groups` WHERE `charid` = ?'
---Select all groups the character is a member of.
---@param charid number
---@return { name: string, grade: number }[]?
function db.selectCharacterGroups(charid)
    return MySQL.query.await(SELECT_CHARACTER_GROUPS, { charid })
end

local SELECT_CHARACTER_LICENSES = 'SELECT `name`, DATE_FORMAT(`issued`, "%d/%m/%Y") AS `issued` FROM `character_licenses` WHERE `charid` = ?'
---@param charid number
---@return { name: string, issued: string }[]?
function db.selectCharacterLicenses(charid)
    return MySQL.query.await(SELECT_CHARACTER_LICENSES, { charid })
end

local ADD_CHARACTER_LICENSE = 'INSERT INTO `character_licenses` (`charid`, `name`, `issued`) VALUES (?, ?, ?)'
---Adds the group to the character.
---@param charid number
---@param name string
---@param issued string
function db.addCharacterLicense(charid, name, issued)
    return MySQL.prepare.await(ADD_CHARACTER_LICENSE, { charid, name, issued })
end

local REMOVE_CHARACTER_LICENSE = 'DELETE FROM `character_licenses` WHERE `charid` = ? AND `name` = ?'
---Removes the group from the user.
---@param charid number
---@param name string
function db.removeCharacterLicense(charid, name)
    return MySQL.prepare.await(REMOVE_CHARACTER_LICENSE, { charid, name })
end

local SELECT_STATEID = 'SELECT 1 FROM `characters` WHERE stateid = ?'

---@param stateid string
function db.isStateIdAvailable(stateid)
    return not MySQL.scalar.await(SELECT_STATEID, { stateid })
end

local UPDATE_STATEID = 'UPDATE characters SET `stateid` = ? WHERE `charid` = ?'

---@param stateid string
---@param charid number
---@return number
function db.updateStateId(stateid, charid)
    return MySQL.update.await(UPDATE_STATEID, { stateid, charid })
end

return db
