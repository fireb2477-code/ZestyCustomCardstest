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
	-- Negate opponent's activation, then destroy it
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
	-- Banish any number of "Masked HERO" monsters
	-- Gain 300 ATK for each
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
-- Archetype codes
---------------------------------------------------

local HERO=0x8
local MASKED_HERO=0xA008


---------------------------------------------------
-- Fusion Material
-- 3 Masked HERO monsters
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(MASKED_HERO)
		and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Alternative Special Summon filter
---------------------------------------------------

function s.spfilter(c,sc)
	return c~=sc
		and c:IsSetCard(MASKED_HERO)
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- Check whether 3 valid materials exist
---------------------------------------------------

function s.checkmaterials(tp,sc)
	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		sc
	)

	if #g<3 then
		return false
	end

	---------------------------------------------------
	-- Check 3 different Attributes
	---------------------------------------------------

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
-- Alternative Special Summon condition
--
-- IMPORTANT:
-- Check materials HERE, not only in sptg().
-- This prevents EDOPro from displaying the card
-- as summonable when there are not enough materials.
---------------------------------------------------

function s.spcon(e,c)
	if c==nil then
		return true
	end

	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	local tp=e:GetHandlerPlayer()

	---------------------------------------------------
	-- Must have a free Extra Monster Zone / valid zone
	---------------------------------------------------

	if Duel.GetLocationCountFromEx(
		tp,
		tp,
		c
	)<=0 then
		return false
	end

	---------------------------------------------------
	-- MUST actually have 3 materials
	---------------------------------------------------

	return s.checkmaterials(tp,c)
end


---------------------------------------------------
-- Special Summon target
---------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return s.checkmaterials(tp,e:GetHandler())
	end

	return true
end


---------------------------------------------------
-- Alternative Special Summon operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	---------------------------------------------------
	-- Get all possible materials
	---------------------------------------------------

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		c
	)

	if #g<3 then
		return
	end

	local sg=Group.CreateGroup()


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

	sg:AddCard(tc1)
	g:RemoveCard(tc1)


	---------------------------------------------------
	-- Select second material
	---------------------------------------------------

	local g2=g:Filter(
		function(mc,attr)
			return mc:GetAttribute()~=attr
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

	sg:AddCard(tc2)
	g:RemoveCard(tc2)


	---------------------------------------------------
	-- Select third material
	---------------------------------------------------

	local g3=g:Filter(
		function(mc,attr1,attr2)
			local attr=mc:GetAttribute()

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

	sg:AddCard(tc3)


	---------------------------------------------------
	-- Banish all 3 materials
	---------------------------------------------------

	if Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_MATERIAL+REASON_FUSION+REASON_COST
	)~=3 then
		return
	end


	---------------------------------------------------
	-- Mark that this card was Special Summoned
	-- by its own procedure
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
-- HERO filter
--
-- IMPORTANT:
-- This is HERO in general, not Masked HERO.
---------------------------------------------------

function s.herofilter(c)
	return c:IsSetCard(HERO)
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- End Phase target
---------------------------------------------------

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


---------------------------------------------------
-- End Phase operation
---------------------------------------------------

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
	-- If there is a HERO in GY:
	-- Banish 1 HERO
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
	-- Otherwise send this card to GY
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
-- ATK gain filter
-- Only Masked HERO
---------------------------------------------------

function s.atkfilter(c)
	return c:IsSetCard(MASKED_HERO)
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- ATK gain target
---------------------------------------------------

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


---------------------------------------------------
-- ATK gain operation
---------------------------------------------------

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
	-- Banish
	---------------------------------------------------

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_EFFECT
	)

	---------------------------------------------------
	-- Gain ATK
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