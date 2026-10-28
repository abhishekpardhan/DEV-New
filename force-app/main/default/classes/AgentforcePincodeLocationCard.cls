/**
 * @File Name          : AgentforcePincodeLocationCard.cls
 * @Description        : Data shown on the pincode location map card in the Agentforce chat.
 *                       Returned by AgentforcePincodeCheck for serviceable pincodes and used by
 *                       the safexpressPincodeLocationType Lightning Type, which is rendered by
 *                       the pincodeLocationCard LWC.
 * @Author             :
 * @Group              :
 * @Last Modified On   : 09-10-2026
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0        09-10-2026                                          Initial Version
 **/
public class AgentforcePincodeLocationCard {

    @InvocableVariable(label='City')
    public String city;

    @InvocableVariable(label='District')
    public String district;

    @InvocableVariable(label='State')
    public String state;

    @InvocableVariable(label='Pincode')
    public String pincode;
}