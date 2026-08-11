--Blue-Eyes Chaos MAX Spirit Dragon
local s,id=GetID()

function s.initial_effect(c)
    ---------------------------------------------------
    -- Synchro Material
    -- 1+ Dragon non-Tuner + 1 Spellcaster Tuner
    ---------------------------------------------------
    c:EnableReviveLimit()

    Synchro.AddProcedure(c,
        s.tfilter,1,1,
        s.ntfilter,1,99
    )

    ---------------------------------------------------
    -- 1. When Synchro Summoned:
    -- Change all opponent's monsters to Defense
    -- Position, then make their ATK/DEF 0
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_POSITION+CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.poscon)
    e1:SetOperation(s.posop)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- 2. Monsters with 0 ATK or 0 DEF
    -- cannot activate their effects
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(0,1)
    e2:SetValue(s.aclimit)
    c:RegisterEffect(e2)

    ---------------------------------------------------
    -- 3. Cannot leave the field by opponent's
    -- card effects
    ---------------------------------------------------

    -- Cannot be sent to GY
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CANNOT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.leavecon)
    e3:SetValue(1)
    c:RegisterEffect(e3)

    -- Cannot be returned to hand
    local e4=e3:Clone()
    e4:SetCode(EFFECT_CANNOT_TO_HAND)
    c:RegisterEffect(e4)

    -- Cannot be returned to Deck
    local e5=e3:Clone()
    e5:SetCode(EFFECT_CANNOT_TO_DECK)
    c:RegisterEffect(e5)

    -- Cannot be banished
    local e6=e3:Clone()
    e6:SetCode(EFFECT_CANNOT_REMOVE)
    c:RegisterEffect(e6)

    -- Cannot have its control changed
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
    e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCondition(s.leavecon)
    c:RegisterEffect(e7)

    -- Cannot be destroyed by opponent's effects
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_SINGLE)
    e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e8:SetValue(s.indval)
    c:RegisterEffect(e8)

    ---------------------------------------------------
    -- 4. Piercing + Double Battle Damage
    ---------------------------------------------------
    local e9=Effect.CreateEffect(c)
    e9:SetType(EFFECT_TYPE_SINGLE)
    e9:SetCode(EFFECT_PIERCE)
    e9:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e9:SetRange(LOCATION_MZONE)
    e9:SetValue(DOUBLE_DAMAGE)
    c:RegisterEffect(e9)
end


---------------------------------------------------
-- Synchro Materials
---------------------------------------------------

function s.tfilter(c)
    return c:IsType(TYPE_TUNER)
        and c:IsRace(RACE_SPELLCASTER)
end

function s.ntfilter(c)
    return not c:IsType(TYPE_TUNER)
        and c:IsRace(RACE_DRAGON)
end


---------------------------------------------------
-- Effect 1
---------------------------------------------------

function s.poscon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    local g=Duel.GetMatchingGroup(
        Card.IsFaceup,
        tp,
        0,
        LOCATION_MZONE,
        nil
    )

    for tc in aux.Next(g) do

        ---------------------------------------------------
        -- Change to Defense Position
        ---------------------------------------------------
        if tc:IsAttackPos() then
            Duel.ChangePosition(
                tc,
                POS_FACEUP_DEFENSE
            )
        end

        ---------------------------------------------------
        -- Set ATK to 0
        ---------------------------------------------------
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK)
        e1:SetValue(0)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)

        ---------------------------------------------------
        -- Set DEF to 0
        ---------------------------------------------------
        local e2=e1:Clone()
        e2:SetCode(EFFECT_SET_DEFENSE)
        tc:RegisterEffect(e2)
    end
end


---------------------------------------------------
-- Effect 2
--
-- Opponent's monster with 0 ATK OR 0 DEF
-- cannot activate its effects
---------------------------------------------------

function s.aclimit(e,re,tp)

    ---------------------------------------------------
    -- Safety check
    ---------------------------------------------------
    if not re then
        return false
    end

    local rc=re:GetHandler()

    if not rc then
        return false
    end

    ---------------------------------------------------
    -- The effect must be activated by the opponent
    ---------------------------------------------------
    if tp~=1-e:GetHandlerPlayer() then
        return false
    end

    ---------------------------------------------------
    -- Handler must be a monster
    ---------------------------------------------------
    if not rc:IsMonster() then
        return false
    end

    ---------------------------------------------------
    -- Monster must currently be on the field
    ---------------------------------------------------
    if not rc:IsOnField() then
        return false
    end

    ---------------------------------------------------
    -- Monster must be controlled by opponent
    ---------------------------------------------------
    if rc:GetControler()~=1-e:GetHandlerPlayer() then
        return false
    end

    ---------------------------------------------------
    -- 0 ATK OR 0 DEF
    ---------------------------------------------------
    return rc:GetAttack()==0
        or rc:GetDefense()==0
end


---------------------------------------------------
-- Cannot leave the field
---------------------------------------------------

function s.leavecon(e)
    local c=e:GetHandler()

    return c:IsSummonType(SUMMON_TYPE_SYNCHRO)
end


---------------------------------------------------
-- Destruction protection
---------------------------------------------------

function s.indval(e,re)
    return re
        and re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end