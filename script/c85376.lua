--Masked HERO Tri-breaker
local s,id=GetID()

function s.initial_effect(c)
	---------------------------------------------------
	-- Fusion Summon
	-- 3 "Masked HERO" monsters with different Attributes
	---------------------------------------------------
	c:EnableReviveLimit()

	Fusion.AddProcMix(c,true,true,
		s.matfilter,
		s.matfilter,
		s.matfilter
	)

	---------------------------------------------------
	-- Alternative Special Summon
	-- Banish 3 "Masked HERO" monsters with different
	-- Attributes from your GY and/or Extra Deck
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
	-- End Phase
	-- If Special Summoned by its own procedure:
	-- Banish 1 "HERO" monster from your GY,
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
	-- Quick Effect
	-- When opponent activates a card/effect:
	-- Negate it, then destroy that card
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
	-- Once per turn
	-- Banish any number of "Masked HERO" monsters
	-- from your GY; this card gains 300 ATK for each
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
-- Constants
---------------------------------------------------

local HERO=0x8
local MASKED_HERO=0xA008


---------------------------------------------------
-- Fusion Material
-- Must be "Masked HERO"
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(MASKED_HERO)
		and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Alternative Special Summon
---------------------------------------------------

function s.spfilter(c)
	return c:IsSetCard(MASKED_HERO)
		and c:IsAbleToRemove()
end


function s.spcon(e,c)
	if c==nil then
		return true
	end

	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	return Duel.GetLocationCountFromEx(
		e:GetHandlerPlayer(),
		e:GetHandlerPlayer(),
		c
	)>0
end


function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return s.checkmaterials(tp)
	end

	return true
end


---------------------------------------------------
-- Check if 3 Masked HERO monsters with
-- different Attributes exist
---------------------------------------------------

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

	for tc1 in aux.Next(g) do
		for tc2 in aux.Next(g) do
			if tc2~=tc1
				and tc1:GetAttribute()~=tc2:GetAttribute()
			then
				for tc3 in aux.Next(g) do
					if tc3~=tc1
						and tc3~=tc2
						and tc3:GetAttribute()~=tc1:GetAttribute()
						and tc3:GetAttribute()~=tc2:GetAttribute()
					then
						return true
					end
				end
			end
		end
	end

	return false
end


---------------------------------------------------
-- Alternative Summon Operation
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

	---------------------------------------------------
	-- Select first material
	---------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc1=g:Select(tp,1,1,nil):GetFirst()

	if not tc1 then
		return
	end

	g:RemoveCard(tc1)

	---------------------------------------------------
	-- Select second material with different Attribute
	---------------------------------------------------

	local g2=g:Filter(
		function(c,attr)
			return c:GetAttribute()~=attr
		end,
		nil,
		tc1:GetAttribute()
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

	g:RemoveCard(tc2)

	---------------------------------------------------
	-- Select third material with different Attribute
	---------------------------------------------------

	local g3=g:Filter(
		function(c,attr1,attr2)
			local attr=c:GetAttribute()

			return attr~=attr1
				and attr~=attr2
		end,
		nil,
		tc1:GetAttribute(),
		tc2:GetAttribute()
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

	---------------------------------------------------
	-- Create material group
	---------------------------------------------------

	local sg=Group.CreateGroup()

	sg:AddCard(tc1)
	sg:AddCard(tc2)
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
	-- Mark Special Summon method
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


---------------------------------------------------
-- HERO monster filter
-- IMPORTANT:
-- This is HERO, NOT Masked HERO.
---------------------------------------------------

function s.herofilter(c)
	return c:IsSetCard(HERO)
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

	---------------------------------------------------
	-- If you have a HERO in GY, you may banish 1
	---------------------------------------------------

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

	---------------------------------------------------
	-- Otherwise send Tri-breaker to GY
	---------------------------------------------------

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
		and Duel.IsChainDisablable(ev)
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

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
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
-- ATK gain
-- Only "Masked HERO"
---------------------------------------------------

function s.atkfilter(c)
	return c:IsSetCard(MASKED_HERO)
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

	return true
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

	---------------------------------------------------
	-- Select any number
	---------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local sg=g:Select(
		tp,
		1,
		# g,
		nil
	)

	---------------------------------------------------
	-- Banish selected Masked HERO monsters
	---------------------------------------------------

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_EFFECT
	)

	---------------------------------------------------
	-- Gain 300 ATK per banished monster
	---------------------------------------------------

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