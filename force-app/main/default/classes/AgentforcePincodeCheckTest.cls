/**
 * @File Name          : AgentforcePincodeCheckTest.cls
 * @Description        : Test class for AgentforcePincodeCheck (Agentforce action
 *                       "Check Pincode Serviceability V2"). Covers SERVICEABLE,
 *                       NOT_SERVICEABLE, INVALID_FORMAT and ERROR paths, input
 *                       trimming, output ordering, de-duplication, bulk behaviour
 *                       and the Location Card output shown to the customer in the chat.
 * @Author             : Geetansh Sharma
 * @Last Modified On   : 12-10-2026
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0        07-10-2026               Geetansh Sharma           Initial Version
 * 1.1        12-10-2026               Geetansh Sharma           Added Location Card assertions
 **/

/**
 * TEST CASES
 * 1. Valid pincode        -> SERVICEABLE + location + Location Card
 * 2. Pincode with spaces  -> trimmed, SERVICEABLE, card holds trimmed pincode
 * 3. Pincode not in data  -> NOT_SERVICEABLE, no Location Card
 * 4. Wrong format / blank -> INVALID_FORMAT, no Location Card, no query
 * 5. Mixed inputs         -> same order, 1 query, card only for serviceable
 * 6. 200 inputs           -> bulk safe, 1 query, card only for serviceable
 * 7. Empty list           -> empty output
 * 8. Exception            -> ERROR for all inputs, no Location Card
 **/

@IsTest
private class AgentforcePincodeCheckTest {

    // Representative rows taken from the Pincode__c data export
    private static final String PIN_NEW_DELHI  = '110001';  // Delhi / NEW DELHI / NEW DELHI
    private static final String PIN_ALIPUR     = '110036';  // Delhi / DELHI NORTH WEST / ALIPUR (DL)
    private static final String PIN_BALLABGARH = '121004';  // Haryana / FARIDABAD / BALLABGARH
    private static final String PIN_NOT_IN_DB  = '999999';  // Valid format, no Pincode__c record

    @TestSetup
    static void setupData() {
        // Name is an auto-number on Pincode__c, so it is not set here.
        // If Branch_Id__c / Branch_Name__c are required in your org, add them below.
        List<Pincode__c> pincodes = new List<Pincode__c>{
            new Pincode__c(Pincode__c = PIN_NEW_DELHI,  State__c = 'Delhi',   City__c = 'NEW DELHI',        District__c = 'NEW DELHI'),
            new Pincode__c(Pincode__c = PIN_ALIPUR,     State__c = 'Delhi',   City__c = 'DELHI NORTH WEST', District__c = 'ALIPUR (DL)'),
            new Pincode__c(Pincode__c = PIN_BALLABGARH, State__c = 'Haryana', City__c = 'FARIDABAD',        District__c = 'BALLABGARH')
        };
        insert pincodes;
    }

    // ------------------------------------------------------------------ helpers

    private static List<AgentforcePincodeCheck.PincodeInput> buildInputs(List<String> pincodes) {
        List<AgentforcePincodeCheck.PincodeInput> inputs = new List<AgentforcePincodeCheck.PincodeInput>();
        for (String pincode : pincodes) {
            AgentforcePincodeCheck.PincodeInput input = new AgentforcePincodeCheck.PincodeInput();
            input.pincode = pincode;
            inputs.add(input);
        }
        return inputs;
    }

    // Checks the status, the location fields and the Location Card for a serviceable pincode
    private static void assertServiceable(AgentforcePincodeCheck.Output output, String pincode,
                                          String city, String district, String state) {
        Assert.areEqual(AgentforcePincodeCheck.STATUS_SERVICEABLE, output.pincodeStatus, 'Pincode should be serviceable');
        Assert.areEqual(city, output.city, 'City should match the Pincode__c record');
        Assert.areEqual(district, output.district, 'District should match the Pincode__c record');
        Assert.areEqual(state, output.state, 'State should match the Pincode__c record');

        // Location Card shown to the customer in the chat
        Assert.isNotNull(output.locationCard, 'Location Card must be populated for a serviceable pincode');
        Assert.areEqual(city, output.locationCard.city, 'Location Card city should match the Pincode__c record');
        Assert.areEqual(district, output.locationCard.district, 'Location Card district should match the Pincode__c record');
        Assert.areEqual(state, output.locationCard.state, 'Location Card state should match the Pincode__c record');
        Assert.areEqual(pincode, output.locationCard.pincode, 'Location Card pincode should be the trimmed pincode');
    }

    // Checks that no location details and no Location Card are returned
    private static void assertNoLocation(AgentforcePincodeCheck.Output output, String expectedStatus) {
        Assert.areEqual(expectedStatus, output.pincodeStatus, 'Unexpected pincode status');
        Assert.isNull(output.city, 'City must be empty when status is ' + expectedStatus);
        Assert.isNull(output.district, 'District must be empty when status is ' + expectedStatus);
        Assert.isNull(output.state, 'State must be empty when status is ' + expectedStatus);
        Assert.isNull(output.locationCard, 'Location Card must be empty when status is ' + expectedStatus);
    }

    // -------------------------------------------------------------- SERVICEABLE

    @IsTest
    static void serviceablePincodeReturnsLocationAndCard() {
        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(buildInputs(new List<String>{ PIN_NEW_DELHI }));
        Test.stopTest();

        Assert.areEqual(1, outputs.size(), 'One output expected per input');
        assertServiceable(outputs[0], PIN_NEW_DELHI, 'NEW DELHI', 'NEW DELHI', 'Delhi');
    }

    @IsTest
    static void pincodeWithSurroundingSpacesIsTrimmed() {
        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(buildInputs(new List<String>{ '  ' + PIN_BALLABGARH + '  ' }));
        Test.stopTest();

        Assert.areEqual(1, outputs.size(), 'One output expected per input');
        // The Location Card must carry the trimmed pincode, not the value with spaces
        assertServiceable(outputs[0], PIN_BALLABGARH, 'FARIDABAD', 'BALLABGARH', 'Haryana');
    }

    // ---------------------------------------------------------- NOT_SERVICEABLE

    @IsTest
    static void validFormatWithoutRecordIsNotServiceable() {
        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(buildInputs(new List<String>{ PIN_NOT_IN_DB }));
        Test.stopTest();

        Assert.areEqual(1, outputs.size(), 'One output expected per input');
        assertNoLocation(outputs[0], AgentforcePincodeCheck.STATUS_NOT_SERVICEABLE);
    }

    // ----------------------------------------------------------- INVALID_FORMAT

    @IsTest
    static void invalidFormatsAreRejectedWithoutQuery() {
        List<String> invalidPincodes = new List<String>{
            '11000A',    // contains a letter
            '11000',     // 5 digits
            '1100011',   // 7 digits
            '110-01',    // contains a symbol
            '110 001',   // inner space
            '',          // empty
            '   ',       // whitespace only
            null         // missing value
        };

        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(buildInputs(invalidPincodes));
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(invalidPincodes.size(), outputs.size(), 'One output expected per input');
        for (AgentforcePincodeCheck.Output output : outputs) {
            assertNoLocation(output, AgentforcePincodeCheck.STATUS_INVALID_FORMAT);
        }
        Assert.areEqual(0, queriesUsed, 'No SOQL should run when no pincode has a valid format');
    }

    // ------------------------------------------------------------- MIXED / ORDER

    @IsTest
    static void mixedInputsKeepOrderAndUseSingleQuery() {
        List<String> pincodes = new List<String>{
            PIN_NEW_DELHI,   // 0 serviceable
            PIN_NOT_IN_DB,   // 1 not serviceable
            'abcdef',        // 2 invalid format
            PIN_BALLABGARH,  // 3 serviceable (Haryana)
            PIN_NEW_DELHI,   // 4 duplicate of 0, still serviceable
            PIN_ALIPUR       // 5 serviceable (different district)
        };

        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(buildInputs(pincodes));
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(pincodes.size(), outputs.size(), 'One output expected per input, in the same order');
        assertServiceable(outputs[0], PIN_NEW_DELHI, 'NEW DELHI', 'NEW DELHI', 'Delhi');
        assertNoLocation(outputs[1], AgentforcePincodeCheck.STATUS_NOT_SERVICEABLE);
        assertNoLocation(outputs[2], AgentforcePincodeCheck.STATUS_INVALID_FORMAT);
        assertServiceable(outputs[3], PIN_BALLABGARH, 'FARIDABAD', 'BALLABGARH', 'Haryana');
        assertServiceable(outputs[4], PIN_NEW_DELHI, 'NEW DELHI', 'NEW DELHI', 'Delhi');
        assertServiceable(outputs[5], PIN_ALIPUR, 'DELHI NORTH WEST', 'ALIPUR (DL)', 'Delhi');
        Assert.areEqual(1, queriesUsed, 'Exactly one SOQL query should run regardless of input count');

        // Duplicate inputs must get their own Location Card, not a shared one
        Assert.areNotEqual(System.hashCode(outputs[0].locationCard), 0, 'Location Card should exist for the first input');
        Assert.isFalse(outputs[0].locationCard === outputs[4].locationCard,
            'Each serviceable output should have its own Location Card instance');
    }

    // ------------------------------------------------------------------- BULK

    @IsTest
    static void bulkInputsStayWithinLimits() {
        List<String> pincodes = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            pincodes.add(Math.mod(i, 2) == 0 ? PIN_NEW_DELHI : PIN_NOT_IN_DB);
        }

        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(buildInputs(pincodes));
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(200, outputs.size(), 'One output expected per input');
        for (Integer i = 0; i < outputs.size(); i++) {
            if (Math.mod(i, 2) == 0) {
                Assert.areEqual(AgentforcePincodeCheck.STATUS_SERVICEABLE, outputs[i].pincodeStatus,
                    'Unexpected status at position ' + i);
                Assert.isNotNull(outputs[i].locationCard, 'Location Card expected at position ' + i);
                Assert.areEqual(PIN_NEW_DELHI, outputs[i].locationCard.pincode,
                    'Unexpected Location Card pincode at position ' + i);
            } else {
                Assert.areEqual(AgentforcePincodeCheck.STATUS_NOT_SERVICEABLE, outputs[i].pincodeStatus,
                    'Unexpected status at position ' + i);
                Assert.isNull(outputs[i].locationCard, 'No Location Card expected at position ' + i);
            }
        }
        Assert.areEqual(1, queriesUsed, 'Bulk call should use a single SOQL query');
    }

    @IsTest
    static void emptyInputListReturnsEmptyOutput() {
        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs =
            AgentforcePincodeCheck.checkPinCode(new List<AgentforcePincodeCheck.PincodeInput>());
        Test.stopTest();

        Assert.isNotNull(outputs, 'Output list should never be null');
        Assert.areEqual(0, outputs.size(), 'No outputs expected for no inputs');
    }

    // ------------------------------------------------------------------ ERROR

    @IsTest
    static void unexpectedExceptionReturnsErrorForEveryInput() {
        // A null element in the input list causes a NullPointerException inside
        // the try block, which drives the catch path (logging + ERROR outputs).
        List<AgentforcePincodeCheck.PincodeInput> inputs = buildInputs(new List<String>{ PIN_NEW_DELHI });
        inputs.add(null);

        Test.startTest();
        List<AgentforcePincodeCheck.Output> outputs = AgentforcePincodeCheck.checkPinCode(inputs);
        Test.stopTest();

        Assert.areEqual(inputs.size(), outputs.size(), 'One ERROR output expected per input');
        for (AgentforcePincodeCheck.Output output : outputs) {
            // ERROR outputs are rebuilt from scratch, so no Location Card may leak through
            assertNoLocation(output, AgentforcePincodeCheck.STATUS_ERROR);
        }
    }
}