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
	-- Banish 3 "Masked HERO" monsters with different
	-- Attributes from your GY and/or Extra Deck
	---------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
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
-- Fusion Material
-- "Masked HERO" monsters
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x8)
		and c:IsType(TYPE_MONSTER)
		and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Alternative Special Summon
---------------------------------------------------

function s.spfilter(c,e,tp)
	return c~=e:GetHandler()
		and c:IsSetCard(0x8)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- Check whether 3 different Attributes exist
---------------------------------------------------

function s.checkmaterials(tp,e)
	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		nil,
		e,
		tp
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
-- Special Summon condition
---------------------------------------------------

function s.spcon(e,c)
	if c==nil then
		return true
	end

	local tp=c:GetControler()

	---------------------------------------------------
	-- Must have a free Extra Monster Zone / Main
	-- Monster Zone that can receive the Fusion Monster
	---------------------------------------------------
	if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then
		return false
	end

	---------------------------------------------------
	-- Must have 3 different-Attribute materials
	---------------------------------------------------
	return s.checkmaterials(tp,e)
end


---------------------------------------------------
-- Select the 3 materials
---------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return s.checkmaterials(tp,e)
	end

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		nil,
		e,
		tp
	)

	---------------------------------------------------
	-- Select first material
	---------------------------------------------------
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local sg=Group.CreateGroup()

	local tc1=g:Select(tp,1,1,nil):GetFirst()

	if not tc1 then
		return
	end

	sg:AddCard(tc1)
	g:RemoveCard(tc1)

	---------------------------------------------------
	-- Select second material
	-- Different Attribute
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

	sg:AddCard(tc2)
	g:RemoveCard(tc2)

	---------------------------------------------------
	-- Select third material
	-- Different from both previous Attributes
	---------------------------------------------------
	local g3=g:Filter(
		function(c,attr1,attr2)
			return c:GetAttribute()~=attr1
				and c:GetAttribute()~=attr2
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
	-- Store materials
	---------------------------------------------------
	Duel.SetTargetCard(sg)
	e:SetLabelObject(sg)
end


---------------------------------------------------
-- Special Summon operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sg=e:GetLabelObject()

	if not sg or #sg~=3 then
		return
	end

	---------------------------------------------------
	-- Make sure all selected cards are still valid
	---------------------------------------------------
	local rg=sg:Filter(
		function(tc)
			return tc:IsLocation(LOCATION_GRAVE+LOCATION_EXTRA)
				and tc:IsAbleToRemove()
		end,
		nil
	)

	if #rg~=3 then
		return
	end

	---------------------------------------------------
	-- Banish the 3 materials
	---------------------------------------------------
	if Duel.Remove(
		rg,
		POS_FACEUP,
		REASON_MATERIAL+REASON_FUSION
	)~=3 then
		return
	end

	---------------------------------------------------
	-- Mark this card as Special Summoned by
	-- its own alternative procedure
	---------------------------------------------------
	c:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD,
		0,
		1
	)

	---------------------------------------------------
	-- Clear stored group
	---------------------------------------------------
	e:SetLabelObject(nil)
end


---------------------------------------------------
-- End Phase condition
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end


---------------------------------------------------
-- HERO monster filter
---------------------------------------------------

function s.herofilter(c)
	return c:IsSetCard(0x8)
		and c:IsType(TYPE_MONSTER)
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
-- Banish "Masked HERO" monsters
---------------------------------------------------

function s.atkfilter(c)
	return c:IsSetCard(0x8)
		and c:IsType(TYPE_MONSTER)
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
		# g,
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