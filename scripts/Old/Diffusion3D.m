o1 = zeros(4000, 2, 21);
o2 = zeros(4000, 2, 21);
o3 = zeros(4000, 2, 21);
o4 = zeros(4000, 2, 21);
o5 = zeros(4000, 2, 21);

o1 = o(:, :, :, 1);
o2 = o(:, :, :, 2);
o3 = o(:, :, :, 3);
o4 = o(:, :, :, 4);
o5 = o(:, :, :, 5);


t = 0:2:40;
t1 = t*10*2;
t2 = t*(10+12.5)*2;
t3 = t*(10+12.5*2)*2;
t4 = t*(10+12.5*3)*2;
t5 = t*(10+12.5*4)*2;

c1 = get_mag(200, 10, 6, sr, 50, o1, 0.75);
c2 = get_mag(200, 10, 6, sr, 50, o2, 0.75);
c3 = get_mag(200, 10, 6, sr, 50, o3, 0.75);
c4 = get_mag(200, 10, 6, sr, 50, o4, 0.75);
c5 = get_mag(200, 10, 6, sr, 50, o5, 0.75);

plot(t1, c1(1, :), t2, c2(1, :), t3, c3(1, :), t4, c4(1, :), t5, c5(1, :))