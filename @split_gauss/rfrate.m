function W = rfrate(p)
%
%  function W = rfrate(p)
%

if(p.rfrate == 0)
  error('RF rate not yet computed')
else
  W = p.rfrate;
end
