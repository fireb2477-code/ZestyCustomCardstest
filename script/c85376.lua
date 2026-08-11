--Masked HERO Tri-breaker
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	---------------------------------------------------
	-- Fusion Summon
	-- 3 "Masked HERO" monsters with different Attributes
	---------------------------------------------------
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
	-- Banish 1 "HERO" monster from your GY
	-- OR send this card to the GY
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.epcon)
	e1:SetTarget(s.eptg)
	e1:SetOperation(s.epop)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Quick Effect
	-- Negate an opponent's card/effect activation
	-- and destroy that card
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
	-- from your GY and gain 300 ATK for each
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
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0xA008)
		and c:IsMonster()
		and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Alternative Summon Material
--
-- "Masked HERO"
-- Must be able to be banished
-- Exclude Tri-Breaker itself
---------------------------------------------------

function s.spfilter(c,sc)
	return c:IsSetCard(0xA008)
		and c:IsMonster()
		and c:IsAbleToRemove()
		and c~=sc
end


---------------------------------------------------
-- Check whether 3 valid materials exist
---------------------------------------------------

function s.hasmaterials(tp,c)

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		c
	)

	if #g<3 then
		return false
	end

	for tc1 in aux.Next(g) do

		local g2=g:Clone()
		g2:RemoveCard(tc1)

		for tc2 in aux.Next(g2) do

			if tc2:GetAttribute()~=tc1:GetAttribute() then

				local g3=g2:Clone()
				g3:RemoveCard(tc2)

				for tc3 in aux.Next(g3) do

					if tc3:GetAttribute()~=tc1:GetAttribute()
					and tc3:GetAttribute()~=tc2:GetAttribute() then
						return true
					end

				end
			end

		end
	end

	return false
end


---------------------------------------------------
-- Alternative Summon Condition
--
-- IMPORTANT:
-- The engine checks this BEFORE showing the
-- Special Summon procedure.
--
-- Therefore material availability is checked HERE,
-- not only in s.sptg().
---------------------------------------------------

function s.spcon(e,c)

	if c==nil then
		return true
	end

	local tp=e:GetHandlerPlayer()

	---------------------------------------------------
	-- Must have an available Extra Monster Zone /
	-- Main Monster Zone usable by Extra Deck Summon
	---------------------------------------------------

	if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then
		return false
	end

	---------------------------------------------------
	-- Must actually have a valid set of 3 materials
	---------------------------------------------------

	return s.hasmaterials(tp,c)
end


---------------------------------------------------
-- Alternative Summon Target
--
-- No material selection here.
---------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return true
	end

	return true
end


---------------------------------------------------
-- Alternative Summon Operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	---------------------------------------------------
	-- Rebuild material pool
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


	---------------------------------------------------
	-- Select Material 1
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
	-- Select Material 2
	-- Different Attribute
	---------------------------------------------------

	local g2=g:Filter(
		function(tc,first)
			return tc:GetAttribute()~=first:GetAttribute()
		end,
		nil,
		tc1
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
	-- Select Material 3
	-- Different Attribute from both
	---------------------------------------------------

	local g3=g:Filter(
		function(tc,first,second)
			return tc:GetAttribute()~=first:GetAttribute()
			and tc:GetAttribute()~=second:GetAttribute()
		end,
		nil,
		tc1,
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


	---------------------------------------------------
	-- Create material group
	---------------------------------------------------

	local sg=Group.CreateGroup()

	sg:AddCard(tc1)
	sg:AddCard(tc2)
	sg:AddCard(tc3)


	---------------------------------------------------
	-- Final safety checks
	---------------------------------------------------

	if #sg~=3 then
		return
	end

	if sg:IsContains(c) then
		return
	end

	if tc1:GetAttribute()==tc2:GetAttribute()
	or tc1:GetAttribute()==tc3:GetAttribute()
	or tc2:GetAttribute()==tc3:GetAttribute() then
		return
	end


	---------------------------------------------------
	-- Make sure all materials can still be banished
	---------------------------------------------------

	for tc in aux.Next(sg) do

		if not tc:IsLocation(LOCATION_GRAVE+LOCATION_EXTRA)
		or not tc:IsAbleToRemove() then
			return
		end

	end


	---------------------------------------------------
	-- Banish all 3 materials
	---------------------------------------------------

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_MATERIAL+REASON_FUSION+REASON_COST
	)

	if ct~=3 then
		return
	end


	---------------------------------------------------
	-- Mark this card as summoned by its own procedure
	---------------------------------------------------

	c:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,
		0,
		1
	)
end


---------------------------------------------------
-- End Phase Condition
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	return Duel.IsTurnPlayer(tp)
		and c:IsFaceup()
		and c:IsLocation(LOCATION_MZONE)
		and c:GetFlagEffect(id)>0
end


---------------------------------------------------
-- HERO filter
--
-- HERO = 0x8
---------------------------------------------------

function s.herofilter(c)

	return c:IsSetCard(0x8)
		and c:IsMonster()
		and c:IsAbleToRemove()

end


---------------------------------------------------
-- End Phase Target
---------------------------------------------------

function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	local canbanish=Duel.IsExistingMatchingCard(
		s.herofilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil
	)

	local cangy=c:IsAbleToGrave()

	if chk==0 then
		return canbanish or cangy
	end


	if canbanish then

		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			nil,
			1,
			tp,
			LOCATION_GRAVE
		)

	end


	if cangy then

		Duel.SetPossibleOperationInfo(
			0,
			CATEGORY_TOGRAVE,
			c,
			1,
			tp,
			LOCATION_MZONE
		)

	end
end


---------------------------------------------------
-- End Phase Operation
---------------------------------------------------

function s.epop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	local canbanish=Duel.IsExistingMatchingCard(
		s.herofilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil
	)

	local cangy=c:IsAbleToGrave()


	---------------------------------------------------
	-- Both options available
	---------------------------------------------------

	if canbanish and cangy then

		local op=Duel.SelectEffect(
			tp,
			{true,aux.Stringid(id,0)},
			{true,aux.Stringid(id,1)}
		)

		---------------------------------------------------
		-- Banish 1 HERO
		---------------------------------------------------

		if op==1 then

			Duel.Hint(
				HINT_SELECTMSG,
				tp,
				HINTMSG_REMOVE
			)

			local g=Duel.SelectMatchingCard(
				tp,
				s.herofilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				1,
				nil
			)

			if #g>0 then

				Duel.Remove(
					g,
					POS_FACEUP,
					REASON_EFFECT
				)

			end

			return

		---------------------------------------------------
		-- Send Tri-Breaker to GY
		---------------------------------------------------

		else

			Duel.SendtoGrave(
				c,
				REASON_EFFECT
			)

			return
		end
	end


	---------------------------------------------------
	-- Only HERO available
	---------------------------------------------------

	if canbanish then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_REMOVE
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.herofilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			1,
			nil
		)

		if #g>0 then

			Duel.Remove(
				g,
				POS_FACEUP,
				REASON_EFFECT
			)

		end

		return
	end


	---------------------------------------------------
	-- Only Tri-Breaker can be sent to GY
	---------------------------------------------------

	if cangy then

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

	local rc=re:GetHandler()

	if rc
	and rc:IsDestructable()
	and rc:IsRelateToEffect(re) then

		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			rc,
			1,
			0,
			0
		)

	end
end


function s.negop(e,tp,eg,ep,ev,re,r,rp)

	if Duel.NegateActivation(ev) then

		local rc=re:GetHandler()

		if rc
		and rc:IsRelateToEffect(re)
		and rc:IsDestructable() then

			Duel.Destroy(
				rc,
				REASON_EFFECT
			)

		end
	end
end


---------------------------------------------------
-- Masked HERO ATK Effect
---------------------------------------------------

function s.atkfilter(c)

	return c:IsSetCard(0xA008)
		and c:IsMonster()
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