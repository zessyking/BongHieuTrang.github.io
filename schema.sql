-- Chạy toàn bộ trong Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade, username text unique not null, full_name text, role text not null default 'staff' check (role in ('boss','sale','staff')));
create function my_role() returns text language sql stable security definer set search_path=public as $$ select role from profiles where id=auth.uid() $$;
create function on_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into profiles(id,username,full_name) values(new.id,split_part(new.email,'@',1),split_part(new.email,'@',1)); return new; end $$;
create trigger t_new_user after insert on auth.users for each row execute function on_new_user();

create sequence cust_seq start 10;
create table customers(id uuid primary key default gen_random_uuid(), code text unique not null default 'VIP'||nextval('cust_seq'), name text not null, address text, phone text, opening_debt bigint not null default 0, created_at timestamptz default now());
create table products(id uuid primary key default gen_random_uuid(), name text not null, unit text not null, is_cotton boolean not null default false, created_at timestamptz default now());
create table price_history(id uuid primary key default gen_random_uuid(), product_id uuid not null references products, customer_id uuid references customers, price bigint not null, from_date date not null, unique nulls not distinct (product_id,customer_id,from_date));
create table orders(id uuid primary key default gen_random_uuid(), customer_id uuid not null references customers, order_date date not null, note text, created_by uuid default auth.uid(), created_at timestamptz default now());
create table order_items(id uuid primary key default gen_random_uuid(), order_id uuid not null references orders on delete cascade, product_id uuid not null references products, qty numeric(12,2) not null);
create table payments(id uuid primary key default gen_random_uuid(), customer_id uuid not null references customers, pay_date date not null, amount bigint not null, created_at timestamptz default now());

create view customer_list as select id,code,name,phone from customers;
grant select on customer_list to authenticated;

alter table profiles enable row level security; alter table customers enable row level security; alter table products enable row level security;
alter table price_history enable row level security; alter table orders enable row level security; alter table order_items enable row level security; alter table payments enable row level security;

create policy x on profiles for select to authenticated using (id=auth.uid() or my_role()='boss');
create policy x on products for select to authenticated using (true);
create policy y on products for all to authenticated using (my_role()='boss') with check (my_role()='boss');
create policy x on customers for select to authenticated using (my_role() in ('boss','sale'));
create policy y on customers for all to authenticated using (my_role()='boss') with check (my_role()='boss');
create policy x on price_history for select to authenticated using (my_role() in ('boss','sale'));
create policy y on price_history for all to authenticated using (my_role()='boss') with check (my_role()='boss');
create policy x on orders for select to authenticated using (true);
create policy i on orders for insert to authenticated with check (true);
create policy y on orders for all to authenticated using (my_role()='boss') with check (my_role()='boss');
create policy x on order_items for select to authenticated using (true);
create policy i on order_items for insert to authenticated with check (true);
create policy y on order_items for all to authenticated using (my_role()='boss') with check (my_role()='boss');
create policy x on payments for select to authenticated using (my_role() in ('boss','sale'));
create policy i on payments for insert to authenticated with check (my_role() in ('boss','sale'));
create policy y on payments for all to authenticated using (my_role()='boss') with check (my_role()='boss');

insert into products(name,unit,is_cotton) values ('Bông','kg',true),('Thùng keo','thùng',false),('Cuộn phong','cuộn',false),('Cuộn băng dính','cuộn',false);

-- Sau khi tạo user đầu tiên (vd hieu@xuongbong.local) trong Authentication > Users, chạy:
-- update profiles set role='boss' where username='hieu';
-- Nhân viên bán hàng: update profiles set role='sale' where username='...';
