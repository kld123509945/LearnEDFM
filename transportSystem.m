function [sNew] = transportSystem(sN,sNf,vx,vy,vf,Vfm,Vmf,Vff,Dfm,Dmf,phix,phiy)
%  Assembles and solves the transport system. It consists of the
%  subfunctions for advective and diffusive transport
%  ---------------------------------------------------------------------
%  Copyright (C) 2016 by the LearnEDFM authors
% 
%  This file is part of LearnEDFM.
% 
%  LearnEDFM is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
% 
%  LearnEDFM is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
% 
%  You should have received a copy of the GNU General Public License
%  along with LearnEDFM.  If not, see <http://www.gnu.org/licenses/>.
%  ---------------------------------------------------------------------
% 
%  Authors: Gunnar Jansen, University of Neuchatel, 2016 
%           Ivan Lunati, Rouven Kuenze, University of Lausanne, 2012
%
%  Acknowledgement:  Thanks are due to Manav Tyagi and Hadi Hajibeygi for
%                    contributing to the very early development of the code.
%
%  transportSystem(sN,sNf,vx,vy,vf,Vfm,Vmf,Vff,Dfm,Dmf,phix,phiy)
%
%  Input: 
%        sN     (nx,ny)         old transport solution on the matrix
%        sNf    (nf,1)          old transport solution in the fractures
%        vx     (nx+1,ny)       matrix velocity in the x direction
%        vy     (nx,ny+1)       matrix velocity in the y direction
%        vf     (nf,1)          fracture velocity
%        Vfm    (nf,nx*ny)      velocity matrix between fracture and matrix
%        Vmf    (nx*ny,nf)      velocity matrix between matrix and fracture
%        Vff    (nf*nf,nf*nf)   fracture-fracture intersection velocity
%        Dfm    (nf,nx*ny)      coupling matrix between fracture and matrix
%                               for transport diffusion
%        Dmf    (nx*ny,nf)      coupling matrix between matrix and fracture
%                               for transport diffusion
%        phix   (nx+1,ny)       matrix porosity at the interface in
%                               x-direction
%        phiy   (nx,ny+1)       matrix porosity at the interface in
%                               y-direction
%
%  Output: 
%        sNew  (nx*ny+nf,1)     new transport solution vector


global phi phi_f dx dxf dt Dif Nf Nf_f Nf_i K_f

%-------------------------------------------------------------------------%
%    Build Transport System                                               %
%-------------------------------------------------------------------------%
[Up,r]  = transportAdvection(vx,vy,vf,Vfm,Vmf,Vff,Nf,Nf_f,Nf_i);           % Convective Upwind Matrix

if Dif == 0;
   Di = sparse(prod(Nf)+Nf_f,prod(Nf)+Nf_f);
   ri = sparse(prod(Nf)+Nf_f,1);
else
  [Di,ri] = transportDiffusion(Nf,Nf_f,dx,phix,phiy,Dfm,Dmf);              % Diffusive Matrix 
end
   
Ac      = sparse(phi.*prod(dx)/dt);                                        % Accumulation term matrix
Acf = sparse(phi_f.*dxf.*sqrt(12.*K_f)/dt);                                % Accumulation term fracture

Ac = [Ac(:); Acf(:)];                                                      % Combine the accumulation terms
snnf = [sN(:); sNf(:)];                                                    % for matrix and fracture

A       = Up + diag(Ac(:)) + Di;                                           % Stiffness matrix
rhs     = r + ri + sparse(snnf(:).*Ac(:));                                 % Right hand side

%-------------------------------------------------------------------------%
%    Solve Transport System                                               %
%-------------------------------------------------------------------------%
sNew = A\rhs;