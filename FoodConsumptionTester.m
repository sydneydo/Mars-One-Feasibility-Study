plantsupply = caloriccontent;

carriedfood = 120*4*3040.1;
hourlyconsumption = 3040.1*4/24;

CarriedFoodStore = StoreImpl('Carried Food','Material',carriedfood,carriedfood);
GrownFoodStore = StoreImpl('Grown Food','Material',1E7,0);

carriedfoodconsumed = zeros(1,19000);
grownfoodconsumed = zeros(1,19000);
extrafoodneeded = zeros(1,19000);


% Determine simulated growth rate
growthrate = diff(caloriccontent);
[rate, ind, ~] = unique(growthrate);
index = sort(ind);
addedFood = growthrate(index);

% figure, plot(caloriccontent)


for i = 1:19000
    % Grow food
    if ~isempty(find(index == i,1))
        GrownFoodStore.add(growthrate(i));
    end
        
    % Eat Food
    grownfoodconsumed(i) = GrownFoodStore.take(hourlyconsumption);
    
    if grownfoodconsumed(i) < hourlyconsumption
        carriedfoodconsumed(i) = CarriedFoodStore.take(hourlyconsumption-grownfoodconsumed(i));
    end
    
    if (carriedfoodconsumed(i)+grownfoodconsumed(i)) < hourlyconsumption
%         disp(['Not enough food to consume at tick: ',num2str(i)])
        extrafoodneeded(i) = hourlyconsumption-(carriedfoodconsumed(i)+grownfoodconsumed(i));
    end
end 
    
    
% Need an extra 6.841e6 calories to fill gaps on top of what we already
% brought
% Equates to an adidtional 563 days of food
