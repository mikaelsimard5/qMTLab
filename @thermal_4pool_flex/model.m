function [dM, out2, out3] = thermal_4pool(p, t, M, flag, sequence, R1, T2, Td, P, K, dw)
%
%  function dM = thermal_4pool(p, t, M, flag, sequence, R1, T2, Td, P, K, dw)
%
%  ODE file implementing equations of motion for four exchanging pools,
%  each pair has one pool governed by the Bloch equations and another
%  governed by a thermal model  
%
%  t          : time in seconds
%  M          : column vector with eight magnetization components
%               [ M^l_ax M^l_ay M^l_az M^s_az M^l_bx M^l_by M^l_bz M^s_bz ]'
%  sequence   : sequence file such that sequence(t) = gamma*B1(t)
%  R1         : [R1^l_a R1^s_a R1^l_b R1^s_b]
%                longitudinal relaxation in absence of exchange
%  T2         : [T2^l_a T2^s_a T2^l_b T2^s_b]  transverse relaxation
%  Td         : [];
%  P          : [M^l_a /M^s_a /M^s_b]
%  K          : [k_ab kf_a kf_b]
%  F          : ratio of  Mb / Ma
%  dw         : offset frequency of rotating frame = w - w0

if nargin < 3 | isempty(flag)

  if(isa(sequence, 'double'))
    w1 = 0;
  else
    w1 = exp(sqrt(-1)*t*dw)*omega1(sequence,t);
  end
  w1x = real(w1);
  w1y = imag(w1);
  Kab = K(1);
  Kba = Kab*P(1)/(1-P(1));
  Kfa = K(2);
  Kra = Kfa*(1-P(2))/P(2);
  Kfb = K(3);
  Krb = Kfb*(1-P(3))/P(3);
  
  dM = zeros(8,size(M,2));

  MxA = M(1,:);
  MyA = M(2,:);
  MzA = M(3,:);
  MsA = M(4,:);

  MxB = M(5,:);
  MyB = M(6,:);
  MzB = M(7,:);
  MsB = M(8,:);

  dM(1,:) = -MxA/T2(1) - dw*MyA - w1y*MzA - Kab*MxA + Kba*MxB;
  dM(2,:) = -MyA/T2(1) + dw*MxA + w1x*MzA - Kab*MyA + Kba*MyB;
  dM(3,:) = R1(1)*(P(1) - MzA) - Kfa*MzA + Kra*MsA + w1y*MxA - w1x*MyA ...
      - Kab*MzA +Kba*MzB;
  if(isa(sequence, 'double'))
    dM(4,:) = R1(2)*(P(1)*P(2)/(1-P(2)) - MsA) - Kra*MsA + Kfa*MzA;
  else
    dM(4,:) = R1(2)*(P(1)*P(2)/(1-P(2)) - MsA) - Kra*MsA + Kfa*MzA  -pi*abs(w1)^2*lineshape(p.lineshape, T2(2), offset(sequence))*MsA;
  end

  dM(5,:) = -MxB/T2(3) - dw*MyB - w1y*MzB + Kab*MxA - Kba*MxB;
  dM(6,:) = -MyB/T2(3) + dw*MxB + w1x*MzB + Kab*MyA - Kba*MyB;
  dM(7,:) = R1(3)*(1-P(1) - MzB) - Kfb*MzB + Krb*MsB + w1y*MxB - w1x*MyB ...
      + Kab*MzA - Kba*MzB;
  if(isa(sequence, 'double'))
    dM(8,:) = R1(4)*((1-P(1))*P(3)/(1-P(3)) - MsB) - Krb*MsB + Kfb*MzB;
  else
    dM(8,:) = R1(4)*((1-P(1))*P(3)/(1-P(3)) - MsB) - Krb*MsB + Kfb*MzB  -pi*abs(w1)^2*lineshape(p.lineshape, T2(4), offset(sequence))*MsB;
  end

else
  switch(flag)
    case 'init'                           % Return default [tspan,y0,options].
      dM = [0 1];
      out2 = [0 0 1 1];
      out3 = [];
    case 'jacobian'
      if(isa(sequence, 'double'))
        w1 = 0;
      else
        w1 = exp(sqrt(-1)*t*dw)*omega1(sequence,t);
      end
      w1x = real(w1);
      w1y = imag(w1);

      Kab = K(1);
      Kba = Kab*P(1)/(1-P(1));
      Kfa = K(2);
      Kra = Kfa*(1-P(2))/P(2);
      Kfb = K(3);
      Krb = Kfb*(1-P(3))/P(3);
  
      dM = zeros(8);

      dM(1,:) = [-1/T2(1)-Kab    -dw       -w1y    0  Kba  0    0   0 ];
      dM(2,:) = [  dw         -1/T2(1)-Kab  w1x    0   0   Kba  0   0 ]; 
      dM(3,:) = [ w1y     -w1x   -Kfa-R1(1)-Kab    Kra 0   0    Kba 0 ];
      if(isa(sequence, 'double'))
        dM(4,:) = [  0     0      Kfa         -R1(2)-Kra  0   0   0  0];
      else
        dM(4,:) = [  0     0      Kfa         -R1(2)-Kra-pi*abs(w1)^2*lineshape(p.lineshape, T2(2), offset(sequence))  0  0  0  0];
      end
      dM(5,:) = [ Kab  0    0   0  -1/T2(3)-Kba    -dw       -w1y   0  ];
      dM(6,:) = [  0   Kab  0   0    dw         -1/T2(3)-Kba  w1x   0  ]; 
      dM(7,:) = [  0   0    Kab 0   w1y     -w1x   -Kfb-R1(3)-Kba   Krb];
      if(isa(sequence, 'double'))
        dM(8,:) = [  0   0   0  0    0     0      Kfb         -R1(4)-Krb  ];
      else
        dM(8,:) = [  0   0   0  0    0     0      Kfb         -R1(4)-Krb-pi*abs(w1)^2*lineshape(p.lineshape, T2(4), offset(sequence)) ];
      end
    otherwise
      error(['Unknown flag ''' flag '''.']);
  end
end

function g = lorentz(w, T2)
g = T2/pi * 1/(1 + (w*T2)^2);

function g = gaussian(w, T2)
g = T2/sqrt(2*pi)*exp(-0.5* (w * T2)^2);

