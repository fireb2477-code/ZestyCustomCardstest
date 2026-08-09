-- Tearlaments Mirella
-- Custom card
local s,id=GetID()

function s.initial_effect(c)

	--------------------------------------------------
	-- 1. DISCARD: Add 1 "Tearlaments" card
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--------------------------------------------------
	-- 2. Opponent Special Summons a monster:
	-- Special Summon this card, then destroy 1 card
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,0})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--------------------------------------------------
	-- 3. Sent to GY by card effect:
	-- Fusion Summon 1 Fusion Monster
	-- using materials from hand/field/GY,
	-- then place those materials on bottom of Deck
	--------------------------------------------------
	local fusparams={
		matfilter=Card.IsAbleToDeck,
		extrafil=s.extramat,
		extraop=s.extraop,
		gc=Fusion.ForcedHandler,
		extratg=s.extratarget
	}

	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,0})
	e3:SetCondition(s.fuscon)
	e3:SetTarget(Fusion.SummonEffTG(fusparams))
	e3:SetOperation(Fusion.SummonEffOP(fusparams))
	c:RegisterEffect(e3)

end


--------------------------------------------------
-- EFFECT 1
--------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(0x182)
		and c:IsAbleToHand()
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():IsDiscardable()
	end

	Duel.SendtoGrave(
		e:GetHandler(),
		REASON_COST+REASON_DISCARD
	)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoHand(
			g,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			g
		)
	end
end


--------------------------------------------------
-- EFFECT 2
--------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		Card.IsControler,
		1,
		nil,
		1-tp
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
			and Duel.IsExistingMatchingCard(
				Card.IsFaceup,
				1-tp,
				LOCATION_ONFIELD,
				0,
				1,
				nil
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_HAND+LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		nil,
		1,
		1-tp,
		LOCATION_ONFIELD
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	if Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	--------------------------------------------------
	-- Destroy 1 card opponent controls
	--------------------------------------------------

	local g=Duel.GetMatchingGroup(
		Card.IsFaceup,
		1-tp,
		LOCATION_ONFIELD,
		0,
		nil
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DESTROY
	)

	local dg=g:Select(
		tp,
		1,
		1,
		nil
	)

	if #dg>0 then
		Duel.Destroy(
			dg,
			REASON_EFFECT
		)
	end
end


--------------------------------------------------
-- EFFECT 3
--------------------------------------------------

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)

	-- Must be sent to GY by card effect
	if not e:GetHandler():IsReason(REASON_EFFECT) then
		return false
	end

	-- Cannot activate during Damage Step
	if Duel.GetCurrentPhase()==PHASE_DAMAGE then
		return false
	end

	return true
end


--------------------------------------------------
-- Extra Fusion Materials
--
-- Materials can be taken from:
-- Hand
-- Field
-- GY
--------------------------------------------------

function s.extramat(e,tp,mg)

	return Duel.GetMatchingGroup(
		Card.IsAbleToDeck,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

end


--------------------------------------------------
-- Tell engine that the triggering card
-- can be used as Fusion Material
--------------------------------------------------

function s.extratarget(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		e:GetHandler(),
		1,
		tp,
		LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE
	)

end


--------------------------------------------------
-- Send Fusion Materials to bottom of Deck
--------------------------------------------------

function s.extraop(e,tc,tp,sg)

	--------------------------------------------------
	-- Show selected hand/GY materials
	--------------------------------------------------

	local gg=sg:Filter(
		Card.IsLocation,
		nil,
		LOCATION_HAND|LOCATION_GRAVE
	)

	if #gg>0 then
		Duel.HintSelection(
			gg,
			true
		)
	end

	--------------------------------------------------
	-- Confirm face-down materials
	--------------------------------------------------

	local rg=sg:Filter(
		Card.IsFacedown,
		nil
	)

	if #rg>0 then
		Duel.ConfirmCards(
			1-tp,
			rg
		)
	end

	--------------------------------------------------
	-- Put materials on bottom of Deck
	--------------------------------------------------

	Duel.SendtoDeck(
		sg,
		nil,
		SEQ_DECKBOTTOM,
		REASON_EFFECT+
		REASON_MATERIAL+
		REASON_FUSION
	)

	--------------------------------------------------
	-- Sort cards placed on Deck bottom
	--------------------------------------------------

	local dg=Duel.GetOperatedGroup():Filter(
		Card.IsLocation,
		nil,
		LOCATION_DECK
	)

	local ct=dg:FilterCount(
		Card.IsControler,
		nil,
		tp
	)

	if ct>0 then
		Duel.SortDeckbottom(
			tp,
			tp,
			ct
		)
	end

	if #dg>ct then
		Duel.SortDeckbottom(
			tp,
			1-tp,
			#dg-ct
		)
	end

	sg:Clear()

end