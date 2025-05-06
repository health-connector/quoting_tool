# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Parsers::Products::PlanAttributesParser do
  let(:xml_string) do
    <<-XML
      <planAttributes>
        <standardComponentID>12345</standardComponentID>
        <planMarketingName>Sample Health Plan</planMarketingName>
        <hiosProductID>67890</hiosProductID>
        <hpid>HPID123</hpid>
        <networkID>NETWORK123</networkID>
        <serviceAreaID>SERVICE123</serviceAreaID>
        <formularyID>FORM123</formularyID>
        <isNewPlan>Yes</isNewPlan>
        <planType>HMO</planType>
        <metalLevel>Gold</metalLevel>
        <uniquePlanDesign>No</uniquePlanDesign>
        <qhpOrNonQhp>QHP</qhpOrNonQhp>
        <ehbPercentPremium>95.0</ehbPercentPremium>
        <insurancePlanPregnancyNoticeReqInd>Yes</insurancePlanPregnancyNoticeReqInd>
        <isSpecialistReferralRequired>Yes</isSpecialistReferralRequired>
        <healthCareSpecialistReferralType>Required</healthCareSpecialistReferralType>
        <insurancePlanBenefitExclusionText>Some exclusions apply</insurancePlanBenefitExclusionText>
        <indianPlanVariation>No</indianPlanVariation>
        <hsaEligibility>Yes</hsaEligibility>
        <employerHSAHRAContributionIndicator>Yes</employerHSAHRAContributionIndicator>
        <empContributionAmountForHSAOrHRA>1000</empContributionAmountForHSAOrHRA>
        <childOnlyOffering>No</childOnlyOffering>
        <childOnlyPlanID></childOnlyPlanID>
        <isWellnessProgramOffered>Yes</isWellnessProgramOffered>
        <isDiseaseMgmtProgramsOffered>Yes</isDiseaseMgmtProgramsOffered>
        <ehbApportionmentForPediatricDental>0.5</ehbApportionmentForPediatricDental>
        <guaranteedVsEstimatedRate>Guaranteed</guaranteedVsEstimatedRate>
        <maximumCoinsuranceForSpecialtyDrugs>30</maximumCoinsuranceForSpecialtyDrugs>
        <maxNumDaysForChargingInpatientCopay>5</maxNumDaysForChargingInpatientCopay>
        <beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays>3</beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays>
        <beginPrimaryCareCostSharingAfterSetNumberVisits>2</beginPrimaryCareCostSharingAfterSetNumberVisits>
        <planEffectiveDate>01/01/2023</planEffectiveDate>
        <planExpirationDate>12/31/2023</planExpirationDate>
        <outOfCountryCoverage>Yes</outOfCountryCoverage>
        <outOfCountryCoverageDescription>Coverage available worldwide</outOfCountryCoverageDescription>
        <outOfServiceAreaCoverage>Yes</outOfServiceAreaCoverage>
        <outOfServiceAreaCoverageDescription>Coverage available nationwide</outOfServiceAreaCoverageDescription>
        <nationalNetwork>Yes</nationalNetwork>
        <summaryBenefitAndCoverageURL>http://example.com/sbc</summaryBenefitAndCoverageURL>
        <enrollmentPaymentURL>http://example.com/enroll</enrollmentPaymentURL>
        <planBrochure>http://example.com/brochure</planBrochure>
      </planAttributes>
    XML
  end

  let(:xml_string_missing) do
    <<-XML
      <planAttributes>
        <standardComponentID>12345</standardComponentID>
        <planMarketingName>Sample Health Plan</planMarketingName>
        <hiosProductID>67890</hiosProductID>
        <hpid>HPID123</hpid>
        <networkID>NETWORK123</networkID>
        <serviceAreaID>SERVICE123</serviceAreaID>
        <formularyID>FORM123</formularyID>
        <isNewPlan>Yes</isNewPlan>
        <planType>HMO</planType>
        <metalLevel>Gold</metalLevel>
        <uniquePlanDesign>No</uniquePlanDesign>
        <qhpOrNonQhp>QHP</qhpOrNonQhp>
        <ehbPercentPremium>95.0</ehbPercentPremium>
        <insurancePlanPregnancyNoticeReqInd>Yes</insurancePlanPregnancyNoticeReqInd>
        <isSpecialistReferralRequired>Yes</isSpecialistReferralRequired>
        <healthCareSpecialistReferralType>Required</healthCareSpecialistReferralType>
        <insurancePlanBenefitExclusionText>Some exclusions apply</insurancePlanBenefitExclusionText>
        <indianPlanVariation>No</indianPlanVariation>
        <empContributionAmountForHSAOrHRA>1000</empContributionAmountForHSAOrHRA>
        <childOnlyOffering>No</childOnlyOffering>
        <childOnlyPlanID></childOnlyPlanID>
        <isWellnessProgramOffered>Yes</isWellnessProgramOffered>
        <isDiseaseMgmtProgramsOffered>Yes</isDiseaseMgmtProgramsOffered>
        <ehbApportionmentForPediatricDental>0.5</ehbApportionmentForPediatricDental>
        <guaranteedVsEstimatedRate>Guaranteed</guaranteedVsEstimatedRate>
        <maximumCoinsuranceForSpecialtyDrugs>30</maximumCoinsuranceForSpecialtyDrugs>
        <maxNumDaysForChargingInpatientCopay>5</maxNumDaysForChargingInpatientCopay>
        <beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays>3</beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays>
        <beginPrimaryCareCostSharingAfterSetNumberVisits>2</beginPrimaryCareCostSharingAfterSetNumberVisits>
        <planEffectiveDate>01/01/2023</planEffectiveDate>
        <planExpirationDate>12/31/2023</planExpirationDate>
        <outOfCountryCoverage>Yes</outOfCountryCoverage>
        <outOfCountryCoverageDescription>Coverage available worldwide</outOfCountryCoverageDescription>
        <outOfServiceAreaCoverage>Yes</outOfServiceAreaCoverage>
        <outOfServiceAreaCoverageDescription>Coverage available nationwide</outOfServiceAreaCoverageDescription>
        <nationalNetwork>Yes</nationalNetwork>
        <enrollmentPaymentURL>http://example.com/enroll</enrollmentPaymentURL>
      </planAttributes>
    XML
  end

  let(:parser) { described_class.parse(xml_string) }
  let(:parser_missing) { described_class.parse(xml_string_missing) }

  describe '#parse' do
    it 'correctly parses XML attributes' do
      expect(parser.standard_component_id).to eq('12345')
      expect(parser.plan_marketing_name).to eq('Sample Health Plan')
      expect(parser.hios_product_id).to eq('67890')
      expect(parser.hpid).to eq('HPID123')
      expect(parser.network_id).to eq('NETWORK123')
      expect(parser.metal_level).to eq('Gold')
      expect(parser.is_specialist_referral_required).to eq('Yes')
      expect(parser.health_care_specialist_referral_type).to eq('Required')
    end
  end

  describe '#parse with missing elements' do
    let(:result_missing) { parser_missing.to_hash }

    context 'when some fields are missing' do
      #   before do
      #     allow(parser).to receive(:hsa_eligibility).and_raise(StandardError)
      #     allow(parser).to receive(:employer_hsa_hra_contribution_indicator).and_raise(StandardError)
      #     allow(parser).to receive(:summary_benefit_and_coverage_url).and_raise(StandardError)
      #     allow(parser).to receive(:plan_brochure).and_raise(StandardError)
      #   end

      it 'handles exceptions gracefully' do
        expect(result_missing[:hsa_eligibility]).to eq('')
        expect(result_missing[:employer_hsa_hra_contribution_indicator]).to eq('')
        expect(result_missing[:summary_benefit_and_coverage_url]).to eq('')
        expect(result_missing[:plan_brochure]).to eq('')
      end
    end
  end

  describe '#to_hash' do
    let(:result) { parser.to_hash }

    it 'converts parsed data to a hash with correct values' do
      expect(result[:standard_component_id]).to eq('12345')
      expect(result[:plan_marketing_name]).to eq('Sample Health Plan')
      expect(result[:hios_product_id]).to eq('67890')
      expect(result[:metal_level]).to eq('Gold')
      expect(result[:is_specialist_referral_required]).to eq('Yes')
      expect(result[:health_care_specialist_referral_type]).to eq('Required')
    end

    context 'when metal level is "expanded bronze"' do
      before do
        allow(parser).to receive(:metal_level).and_return("expanded bronze")
      end

      it 'normalizes the metal level to "bronze"' do
        expect(result[:metal_level]).to eq('bronze')
      end
    end

    context 'when optional fields are not present' do
      before do
        allow(parser).to receive_messages(is_specialist_referral_required: nil, health_care_specialist_referral_type: nil)
      end

      it 'does not include specialist referral fields' do
        expect(result[:is_specialist_referral_required]).to eq('')
        expect(result[:health_care_specialist_referral_type]).to eq('')
      end
    end

    context 'when values contain newlines' do
      before do
        allow(parser).to receive_messages(plan_marketing_name: "Sample Plan \nWith Newline", network_id: "\nNETWORK123\n")
      end

      it 'strips newlines from values' do
        expect(result[:plan_marketing_name]).to eq('Sample Plan With Newline')
        expect(result[:network_id]).to eq('NETWORK123')
      end
    end

    context 'when enrollment_payment_url is present' do
      it 'includes the enrollment_payment_url in the hash' do
        expect(result[:enrollment_payment_url]).to eq('http://example.com/enroll')
      end
    end

    context 'when enrollment_payment_url is not present' do
      before do
        allow(parser).to receive(:enrollment_payment_url).and_return(nil)
      end

      it 'sets enrollment_payment_url as an empty string' do
        expect(result[:enrollment_payment_url]).to eq('')
      end
    end

    context 'when ehb_percent_premium is present' do
      it 'includes the ehb_percent_premium in the hash' do
        expect(result[:ehb_percent_premium]).to eq('95.0')
      end
    end

    context 'when ehb_percent_premium is not present' do
      before do
        allow(parser).to receive(:ehb_percent_premium).and_return(nil)
      end

      it 'sets ehb_percent_premium as an empty string' do
        expect(result[:ehb_percent_premium]).to eq('')
      end
    end
  end
end
