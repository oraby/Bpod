function SetBankFlowRate(OlfIP, Bank, FlowRate)

if isnumeric(OlfIP) % in case OlfIP is a number instead of a string
    IPString = [num2str(OlfIP(1)) '.' num2str(OlfIP(2)) '.' num2str(OlfIP(3)) '.' num2str(OlfIP(4))];
else
    IPString = OlfIP;
end

try
    TCPWrite(IPString, 3336, ['WRITE BankFlow' num2str(Bank) '_Actuator ' num2str(FlowRate)]);
catch
    error('Connection Error!')
end