--Masked HERO Tri-breaker
local s,id=GetID()

function s.initial_effect(c)
    ---------------------------------------------------
    -- Fusion Summon
    -- 3 "Masked HERO" monsters with different Attributes
    ---------------------------------------------------
    c:EnableReviveLimit()

    Fusion.AddProcMix(c,true,true,s.matfilter,s.matfilter,s.matfilter)

    ---------------------------------------------------
    -- Alternative Special Summon
    -- Banish the 3 materials from GY and/or Extra Deck
    ---------------------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.spcon)
    e0:SetTarget(s.sptg)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)

    ---------------------------------------------------
    -- End Phase:
    -- If Special Summoned by its own procedure,
    -- banish 1 "HERO" monster from your GY
    -- OR send this card to the GY
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_PHASE+PHASE_END)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCondition(s.epcon)
    e1:SetTarget(s.eptg)
    e1:SetOperation(s.epop)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- Quick Effect:
    -- Negate activation, and if you do, destroy it
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.negcon)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)

    ---------------------------------------------------
    -- Once per turn:
    -- Banish any number of "Masked HERO" monsters
    -- from your GY, then gain 300 ATK for each
    ---------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+100)
    e3:SetTarget(s.atktg)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)
end


---------------------------------------------------
-- Masked HERO material
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
    return c:IsSetCard(0x8)
        and c:IsType(TYPE_FUSION)
        and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Check 3 different Attributes
---------------------------------------------------

function s.matcheck(g)
    if #g~=3 then
        return false
    end

    local a1=g:GetFirst():GetAttribute()
    local tc=g:GetNext()
    local a2=tc:GetAttribute()
    tc=g:GetNext()
    local a3=tc:GetAttribute()

    return a1~=a2 and a1~=a3 and a2~=a3
end


---------------------------------------------------
-- Alternative Special Summon condition
---------------------------------------------------

function s.spfilter(c)
    return c:IsSetCard(0x8)
        and c:IsType(TYPE_FUSION)
        and c:IsAbleToRemove()
end

function s.spcon(e,c)
    if c==nil then
        return true
    end

    if c:IsLocation(LOCATION_EXTRA) then
        return Duel.GetLocationCountFromEx(
            e:GetHandlerPlayer(),
            e:GetHandlerPlayer(),
            c
        )>0
    end

    return false
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return s.checkmaterials(tp)
    end
end

function s.checkmaterials(tp)
    local g=Duel.GetMatchingGroup(
        s.spfilter,
        tp,
        LOCATION_GRAVE+LOCATION_EXTRA,
        0,
        nil
    )

    if #g<3 then
        return false
    end

    local sg=Group.CreateGroup()

    for tc in aux.Next(g) do
        sg:AddCard(tc)

        local rest=g:Clone()
        rest:RemoveCard(tc)

        for tc2 in aux.Next(rest) do
            if tc2:GetAttribute()~=tc:GetAttribute() then

                local rest2=rest:Clone()
                rest2:RemoveCard(tc2)

                for tc3 in aux.Next(rest2) do
                    if tc3:GetAttribute()~=tc:GetAttribute()
                    and tc3:GetAttribute()~=tc2:GetAttribute()
                    then
                        return true
                    end
                end
            end
        end

        sg:RemoveCard(tc)
    end

    return false
end


---------------------------------------------------
-- Alternative Summon operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    local g=Duel.GetMatchingGroup(
        s.spfilter,
        tp,
        LOCATION_GRAVE+LOCATION_EXTRA,
        0,
        nil
    )

    local sg=Group.CreateGroup()

    ---------------------------------------------------
    -- Select first material
    ---------------------------------------------------
    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_REMOVE
    )

    local tc=g:Select(tp,1,1,nil):GetFirst()
    if not tc then
        return
    end

    sg:AddCard(tc)
    g:RemoveCard(tc)

    ---------------------------------------------------
    -- Select second with different Attribute
    ---------------------------------------------------
    local g2=g:Filter(
        function(mc,first)
            return mc:GetAttribute()~=first:GetAttribute()
        end,
        nil,
        tc
    )

    if #g2==0 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_REMOVE
    )

    local tc2=g2:Select(tp,1,1,nil):GetFirst()
    if not tc2 then
        return
    end

    sg:AddCard(tc2)
    g:RemoveCard(tc2)

    ---------------------------------------------------
    -- Select third with different Attribute
    ---------------------------------------------------
    local g3=g:Filter(
        function(mc,first,second)
            return mc:GetAttribute()~=first:GetAttribute()
                and mc:GetAttribute()~=second:GetAttribute()
        end,
        nil,
        tc,
        tc2
    )

    if #g3==0 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_REMOVE
    )

    local tc3=g3:Select(tp,1,1,nil):GetFirst()
    if not tc3 then
        return
    end

    sg:AddCard(tc3)

    ---------------------------------------------------
    -- Banish materials
    ---------------------------------------------------
    if Duel.Remove(
        sg,
        POS_FACEUP,
        REASON_MATERIAL+REASON_FUSION+REASON_COST
    )~=3 then
        return
    end

    ---------------------------------------------------
    -- Mark that this was Special Summoned
    -- by the alternative procedure
    ---------------------------------------------------
    c:RegisterFlagEffect(
        id,
        RESET_EVENT+RESETS_STANDARD,
        0,
        1
    )
end


---------------------------------------------------
-- End Phase condition
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetFlagEffect(id)>0
end


function s.herofilter(c)
    return c:IsSetCard(0x8)
        and c:IsAbleToRemove()
end


function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.herofilter,
            tp,
            LOCATION_GRAVE,
            0,
            1,
            nil
        )
        or e:GetHandler():IsAbleToGrave()
    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_REMOVE,
        nil,
        1,
        tp,
        LOCATION_GRAVE
    )

    Duel.SetOperationInfo(
        0,
        CATEGORY_TOGRAVE,
        e:GetHandler(),
        1,
        tp,
        LOCATION_MZONE
    )
end


function s.epop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    local g=Duel.GetMatchingGroup(
        s.herofilter,
        tp,
        LOCATION_GRAVE,
        0,
        nil
    )

    if #g>0 then
        Duel.Hint(
            HINT_SELECTMSG,
            tp,
            HINTMSG_REMOVE
        )

        local tc=g:Select(tp,1,1,nil):GetFirst()

        if tc then
            Duel.Remove(
                tc,
                POS_FACEUP,
                REASON_EFFECT
            )
            return
        end
    end

    if c:IsRelateToEffect(e) then
        Duel.SendtoGrave(
            c,
            REASON_EFFECT
        )
    end
end


---------------------------------------------------
-- Negate opponent's card/effect
---------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp
end


function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsChainDisablable(ev)
    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_NEGATE,
        eg,
        1,
        0,
        0
    )
end


function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        Duel.Destroy(
            eg,
            REASON_EFFECT
        )
    end
end


---------------------------------------------------
-- Banish any number of Masked HERO
---------------------------------------------------

function s.atkfilter(c)
    return c:IsSetCard(0x8)
        and c:IsAbleToRemove()
end


function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.atkfilter,
            tp,
            LOCATION_GRAVE,
            0,
            1,
            nil
        )
    end
end


function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    local g=Duel.GetMatchingGroup(
        s.atkfilter,
        tp,
        LOCATION_GRAVE,
        0,
        nil
    )

    if #g==0 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_REMOVE
    )

    local sg=g:Select(
        tp,
        1,
        #g,
        nil
    )

    local ct=Duel.Remove(
        sg,
        POS_FACEUP,
        REASON_EFFECT
    )

    if ct>0 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(ct*300)
        e1:SetReset(
            RESET_EVENT+RESETS_STANDARD_DISABLE
        )
        c:RegisterEffect(e1)
    end
end